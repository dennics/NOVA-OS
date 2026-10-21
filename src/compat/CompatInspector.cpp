#include "CompatInspector.hpp"

#include <QByteArray>
#include <QFile>
#include <QFileInfo>
#include <QtGlobal>
#include <algorithm>
#include <array>

namespace {

quint16 u16(const QByteArray &data, qsizetype offset)
{
    return quint8(data.at(offset)) | (quint16(quint8(data.at(offset + 1))) << 8);
}

quint32 u32(const QByteArray &data, qsizetype offset)
{
    return quint32(u16(data, offset)) | (quint32(u16(data, offset + 2)) << 16);
}

QByteArray readAt(QFile &file, quint64 offset, qint64 length)
{
    if (length < 0 || offset > quint64(file.size()) || quint64(length) > quint64(file.size()) - offset
        || !file.seek(qint64(offset))) return {};
    return file.read(length);
}

struct Section {
    quint32 virtualAddress = 0;
    quint32 virtualSize = 0;
    quint32 rawSize = 0;
    quint32 rawAddress = 0;
};

quint64 fileOffset(quint32 rva, const QList<Section> &sections, qint64 fileSize)
{
    for (const Section &section : sections) {
        const quint64 start = section.virtualAddress;
        const quint64 span = std::max(section.virtualSize, section.rawSize);
        if (quint64(rva) < start || quint64(rva) - start >= span) continue;
        const quint64 displacement = quint64(rva) - start;
        if (displacement >= section.rawSize) return quint64(fileSize);
        const quint64 offset = quint64(section.rawAddress) + displacement;
        return offset < quint64(fileSize) ? offset : quint64(fileSize);
    }
    return quint64(fileSize);
}

QString utf16Value(const QByteArray &data, qsizetype start, qsizetype bytes)
{
    QString value;
    const qsizetype end = std::min(data.size(), start + bytes);
    for (qsizetype cursor = start; cursor + 1 < end; cursor += 2) {
        const auto ch = u16(data, cursor);
        if (ch == 0) break;
        value.append(QChar(ch));
    }
    return value;
}

qsizetype aligned4(qsizetype offset) { return (offset + 3) & ~qsizetype(3); }

QString productNameInBlock(const QByteArray &data, qsizetype start, qsizetype limit, int depth)
{
    if (depth > 5 || start < 0 || start + 6 > limit || limit > data.size()) return {};
    const qsizetype length = u16(data, start);
    const qsizetype valueLength = u16(data, start + 2);
    const auto type = u16(data, start + 4);
    if (length < 8 || length > limit - start) return {};
    const qsizetype end = start + length;
    qsizetype keyEnd = start + 6;
    while (keyEnd + 1 < end && u16(data, keyEnd) != 0) keyEnd += 2;
    if (keyEnd + 1 >= end) return {};
    const QString key = utf16Value(data, start + 6, keyEnd - (start + 6));
    const qsizetype valueStart = aligned4(keyEnd + 2);
    const qsizetype valueBytes = valueLength * (type == 1 ? 2 : 1);
    if (valueStart > end || valueBytes > end - valueStart) return {};
    if (key.compare(QStringLiteral("ProductName"), Qt::CaseInsensitive) == 0 && type == 1)
        return utf16Value(data, valueStart, valueBytes).trimmed();
    for (qsizetype child = aligned4(valueStart + valueBytes); child + 6 <= end;) {
        const qsizetype childLength = u16(data, child);
        if (childLength < 8 || childLength > end - child) break;
        const QString found = productNameInBlock(data, child, end, depth + 1);
        if (!found.isEmpty()) return found;
        child = aligned4(child + childLength);
    }
    return {};
}

QString embeddedProductName(QFile &file, quint32 resourceRva, const QList<Section> &sections)
{
    if (resourceRva == 0) return {};
    const quint64 base = fileOffset(resourceRva, sections, file.size());
    if (base == quint64(file.size())) return {};
    quint32 directory = 0;
    for (int level = 0; level < 3; ++level) {
        if (directory > 32U * 1024U * 1024U) return {};
        const QByteArray header = readAt(file, base + directory, 16);
        if (header.size() != 16) return {};
        const quint32 count = quint32(u16(header, 12)) + u16(header, 14);
        if (count == 0 || count > 1024) return {};
        const QByteArray entries = readAt(file, base + directory + 16, qint64(count) * 8);
        if (entries.size() != qint64(count) * 8) return {};
        quint32 next = 0;
        bool found = false;
        for (quint32 index = 0; index < count; ++index) {
            const auto id = u32(entries, index * 8);
            if (level == 0 && id != 16) continue; // RT_VERSION
            next = u32(entries, index * 8 + 4);
            found = true;
            break;
        }
        if (!found) return {};
        if (level < 2) {
            if ((next & 0x80000000U) == 0) return {};
            directory = next & 0x7fffffffU;
            continue;
        }
        if (next & 0x80000000U) return {};
        const QByteArray dataEntry = readAt(file, base + next, 16);
        if (dataEntry.size() != 16) return {};
        const quint32 dataRva = u32(dataEntry, 0);
        const quint32 dataSize = u32(dataEntry, 4);
        if (dataSize == 0 || dataSize > 1024U * 1024U) return {};
        const quint64 offset = fileOffset(dataRva, sections, file.size());
        const QByteArray versionInfo = readAt(file, offset, dataSize);
        if (versionInfo.size() != dataSize) return {};
        return productNameInBlock(versionInfo, 0, versionInfo.size(), 0);
    }
    return {};
}

void identifyNativeVersion(CompatReport &report)
{
    // ProductName is embedded in the PE version resource. It is a useful hint,
    // but not a signature or proof that the file comes from that publisher.
    const QString product = report.productName.trimmed().toCaseFolded();
    if (product == QStringLiteral("blender")) {
        report.nativeName = QStringLiteral("Blender");
        report.nativeUrl = QStringLiteral("https://www.blender.org/download/");
    } else if (product == QStringLiteral("vlc media player")) {
        report.nativeName = QStringLiteral("VLC media player");
        report.nativeUrl = QStringLiteral("https://www.videolan.org/vlc/");
    } else if (product == QStringLiteral("obs studio")) {
        report.nativeName = QStringLiteral("OBS Studio");
        report.nativeUrl = QStringLiteral("https://obsproject.com/download");
    } else if (product == QStringLiteral("opera gx")) {
        report.nativeName = QStringLiteral("Opera GX");
        report.nativeUrl = QStringLiteral("https://www.opera.com/gx/linux");
    }
}

} // namespace

CompatReport inspectExecutable(const QString &path, bool wineInstalled)
{
    CompatReport report;
    const QFileInfo info(path);
    report.path = info.absoluteFilePath();
    report.fileName = info.fileName();
    report.wineInstalled = wineInstalled;
    if (!info.exists() || !info.isFile() || !info.isReadable()) {
        report.problem = QStringLiteral("unreadable");
        return report;
    }
    if (info.suffix().compare(QStringLiteral("exe"), Qt::CaseInsensitive) != 0) {
        report.problem = QStringLiteral("extension");
        return report;
    }
    QFile file(report.path);
    if (!file.open(QIODevice::ReadOnly)) {
        report.problem = QStringLiteral("unreadable");
        return report;
    }
    const QByteArray dos = readAt(file, 0, 64);
    if (dos.size() != 64 || dos.left(2) != QByteArrayLiteral("MZ")) {
        report.problem = QStringLiteral("not-pe");
        return report;
    }
    const quint32 peOffset = u32(dos, 0x3c);
    if (peOffset < 64 || peOffset > 4U * 1024U * 1024U) {
        report.problem = QStringLiteral("not-pe");
        return report;
    }
    const QByteArray pe = readAt(file, peOffset, 24);
    if (pe.size() != 24 || pe.left(4) != QByteArrayLiteral("PE\0\0")) {
        report.problem = QStringLiteral("not-pe");
        return report;
    }
    const quint16 machine = u16(pe, 4);
    const quint16 sectionCount = u16(pe, 6);
    const quint16 optionalSize = u16(pe, 20);
    const quint16 characteristics = u16(pe, 22);
    if (sectionCount == 0 || sectionCount > 96 || optionalSize < 96 || optionalSize > 4096) {
        report.problem = QStringLiteral("not-pe");
        return report;
    }
    const QByteArray optional = readAt(file, quint64(peOffset) + 24, optionalSize);
    if (optional.size() != optionalSize) {
        report.problem = QStringLiteral("not-pe");
        return report;
    }
    const quint16 magic = u16(optional, 0);
    const int directoryOffset = magic == 0x10b ? 96 : magic == 0x20b ? 112 : -1;
    if (directoryOffset < 0 || optionalSize < directoryOffset) {
        report.problem = QStringLiteral("not-pe");
        return report;
    }
    if ((characteristics & 0x2000) != 0 || (characteristics & 0x0002) == 0) {
        report.problem = QStringLiteral("not-executable");
        return report;
    }
    if ((machine == 0x014c && magic != 0x10b) || (machine == 0x8664 && magic != 0x20b)) {
        report.problem = QStringLiteral("not-pe");
        return report;
    }
    report.validPe = true;
    switch (machine) {
    case 0x014c: report.architecture = QStringLiteral("x86 (32-bit)"); report.wineArchitecture = true; break;
    case 0x8664: report.architecture = QStringLiteral("x86-64 (64-bit)"); report.wineArchitecture = true; break;
    case 0xaa64: report.architecture = QStringLiteral("ARM64"); break;
    default: report.architecture = QStringLiteral("unknown (0x%1)").arg(machine, 4, 16, QChar('0')); break;
    }
    if (optionalSize >= directoryOffset + 24) {
        const quint32 resourceRva = u32(optional, directoryOffset + 16);
        const QByteArray sectionBytes = readAt(file, quint64(peOffset) + 24 + optionalSize, sectionCount * 40);
        if (sectionBytes.size() == sectionCount * 40) {
            QList<Section> sections;
            for (int index = 0; index < sectionCount; ++index) {
                const int pos = index * 40;
                sections.append({u32(sectionBytes, pos + 12), u32(sectionBytes, pos + 8),
                                 u32(sectionBytes, pos + 16), u32(sectionBytes, pos + 20)});
            }
            report.productName = embeddedProductName(file, resourceRva, sections);
            identifyNativeVersion(report);
        }
    }
    if (!report.wineArchitecture) report.problem = QStringLiteral("architecture");
    else if (!wineInstalled) report.problem = QStringLiteral("wine-missing");
    return report;
}
