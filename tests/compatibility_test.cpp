#include "CompatInspector.hpp"
#include "CompatController.hpp"

#include <QFile>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <QTemporaryDir>
#include <QtTest>
#include <unistd.h>

namespace {
void put16(QByteArray &bytes, int offset, quint16 value)
{
    bytes[offset] = char(value & 0xff);
    bytes[offset + 1] = char(value >> 8);
}

void put32(QByteArray &bytes, int offset, quint32 value)
{
    put16(bytes, offset, value & 0xffff);
    put16(bytes, offset + 2, value >> 16);
}

QByteArray block(const QString &key, const QString &value, const QByteArray &children = {})
{
    QByteArray bytes(6, '\0');
    for (QChar ch : key) {
        bytes.append(char(ch.unicode() & 0xff));
        bytes.append(char(ch.unicode() >> 8));
    }
    bytes.append(QByteArray(2, '\0'));
    while (bytes.size() % 4) bytes.append('\0');
    for (QChar ch : value) {
        bytes.append(char(ch.unicode() & 0xff));
        bytes.append(char(ch.unicode() >> 8));
    }
    if (!value.isEmpty()) bytes.append(QByteArray(2, '\0'));
    while (bytes.size() % 4) bytes.append('\0');
    bytes.append(children);
    put16(bytes, 0, bytes.size());
    put16(bytes, 2, value.isEmpty() ? 0 : value.size() + 1);
    put16(bytes, 4, 1);
    return bytes;
}

QByteArray peFixture(quint16 machine, const QString &product = {})
{
    QByteArray bytes(2048, '\0');
    bytes.replace(0, 2, "MZ");
    put32(bytes, 0x3c, 0x80);
    bytes.replace(0x80, 4, QByteArray("PE\0\0", 4));
    put16(bytes, 0x84, machine);
    put16(bytes, 0x86, 1); // one section
    put16(bytes, 0x94, 0xf0); // optional-header size
    put16(bytes, 0x96, 0x0002); // executable image, not DLL
    const bool pe32 = machine == 0x014c;
    put16(bytes, 0x98, pe32 ? 0x10b : 0x20b);
    put32(bytes, 0x98 + (pe32 ? 96 : 112) + 16, 0x1000); // resource RVA
    const int section = 0x80 + 24 + 0xf0;
    bytes.replace(section, 5, ".rsrc");
    put32(bytes, section + 8, 0x400);
    put32(bytes, section + 12, 0x1000);
    put32(bytes, section + 16, 0x400);
    put32(bytes, section + 20, 0x400);

    if (!product.isEmpty()) {
        const int base = 0x400;
        put16(bytes, base + 14, 1);
        put32(bytes, base + 16, 16); // RT_VERSION
        put32(bytes, base + 20, 0x80000020);
        put16(bytes, base + 0x20 + 14, 1);
        put32(bytes, base + 0x20 + 16, 1);
        put32(bytes, base + 0x20 + 20, 0x80000040);
        put16(bytes, base + 0x40 + 14, 1);
        put32(bytes, base + 0x40 + 16, 0x409);
        put32(bytes, base + 0x40 + 20, 0x60);
        put32(bytes, base + 0x60, 0x1080);
        const QByteArray version = block(QStringLiteral("VS_VERSION_INFO"), {},
            block(QStringLiteral("StringFileInfo"), {},
                block(QStringLiteral("040904B0"), {},
                    block(QStringLiteral("ProductName"), product))));
        put32(bytes, base + 0x64, version.size());
        bytes.replace(base + 0x80, version.size(), version);
    }
    return bytes;
}

QString writeFixture(const QString &directory, const QString &name, const QByteArray &contents)
{
    const QString path = directory + QLatin1Char('/') + name;
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly)) return {};
    if (file.write(contents) != contents.size()) return {};
    return path;
}
} // namespace

class CompatibilityTest : public QObject {
    Q_OBJECT
private slots:
    void rejectsInvalidFiles()
    {
        QTemporaryDir temporary;
        QVERIFY(temporary.isValid());
        const QString text = writeFixture(temporary.path(), QStringLiteral("fake.exe"), "not an executable");
        QVERIFY(!text.isEmpty());
        const auto invalid = inspectExecutable(text, true);
        QVERIFY(!invalid.validPe);
        QCOMPARE(invalid.problem, QStringLiteral("not-pe"));
        const QString wrongExtension = writeFixture(temporary.path(), QStringLiteral("program.txt"), peFixture(0x8664));
        QVERIFY(!wrongExtension.isEmpty());
        QCOMPARE(inspectExecutable(wrongExtension, true).problem, QStringLiteral("extension"));
        QByteArray dll = peFixture(0x8664);
        put16(dll, 0x96, 0x2002);
        const QString disguisedDll = writeFixture(temporary.path(), QStringLiteral("library.exe"), dll);
        QVERIFY(!inspectExecutable(disguisedDll, true).validPe);
        QCOMPARE(inspectExecutable(disguisedDll, true).problem, QStringLiteral("not-executable"));
        QByteArray wrongMagic = peFixture(0x8664);
        put16(wrongMagic, 0x98, 0x10b);
        const QString mismatch = writeFixture(temporary.path(), QStringLiteral("mismatch.exe"), wrongMagic);
        QCOMPARE(inspectExecutable(mismatch, true).problem, QStringLiteral("not-pe"));
    }

    void limitsWineToSupportedArchitecture()
    {
        QTemporaryDir temporary;
        QVERIFY(temporary.isValid());
        const QString x86 = writeFixture(temporary.path(), QStringLiteral("x86.exe"), peFixture(0x014c));
        const QString x64 = writeFixture(temporary.path(), QStringLiteral("x64.exe"), peFixture(0x8664));
        const QString arm = writeFixture(temporary.path(), QStringLiteral("arm.exe"), peFixture(0xaa64));
        QVERIFY(inspectExecutable(x86, true).wineArchitecture);
        QVERIFY(inspectExecutable(x64, true).wineArchitecture);
        const auto unsupported = inspectExecutable(arm, true);
        QVERIFY(unsupported.validPe);
        QVERIFY(!unsupported.wineArchitecture);
        QCOMPARE(unsupported.problem, QStringLiteral("architecture"));
        QCOMPARE(inspectExecutable(x64, false).problem, QStringLiteral("wine-missing"));
    }

    void nativeSuggestionRequiresEmbeddedProduct()
    {
        QTemporaryDir temporary;
        QVERIFY(temporary.isValid());
        const QString namedOnly = writeFixture(temporary.path(), QStringLiteral("blender.exe"), peFixture(0x8664));
        QVERIFY(inspectExecutable(namedOnly, true).nativeName.isEmpty());
        const QString identified = writeFixture(temporary.path(), QStringLiteral("other.exe"),
                                                peFixture(0x8664, QStringLiteral("Blender")));
        const auto report = inspectExecutable(identified, true);
        QCOMPARE(report.productName, QStringLiteral("Blender"));
        QCOMPARE(report.nativeName, QStringLiteral("Blender"));
        QCOMPARE(report.nativeUrl, QStringLiteral("https://www.blender.org/download/"));
    }

    void truncatedResourcesAreSafe()
    {
        QTemporaryDir temporary;
        QVERIFY(temporary.isValid());
        QByteArray bytes = peFixture(0x8664, QStringLiteral("Blender"));
        bytes.truncate(0x460);
        const QString path = writeFixture(temporary.path(), QStringLiteral("truncated.exe"), bytes);
        const auto report = inspectExecutable(path, true);
        QVERIFY(report.validPe);
        QVERIFY(report.nativeName.isEmpty());
    }

    void wineLaunchFailureIsVisible()
    {
        if (geteuid() == 0) QSKIP("Wine launch UI test must run as an unprivileged user.");
        QTemporaryDir temporary;
        QVERIFY(temporary.isValid());
        const QString exe = writeFixture(temporary.path(), QStringLiteral("program.exe"), peFixture(0x8664));
        const QString fakeWine = temporary.path() + QStringLiteral("/wine");
        QFile launcher(fakeWine);
        QVERIFY(launcher.open(QIODevice::WriteOnly));
        const QByteArray script = "#!/bin/sh\nprintf 'NOVA_FAKE_WINE_START\\n'\nprintf 'synthetic Wine failure\\n' >&2\nexit 7\n";
        QCOMPARE(launcher.write(script), qint64(script.size()));
        launcher.close();
        QVERIFY(launcher.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner));

        const QByteArray oldPath = qgetenv("PATH");
        qputenv("PATH", temporary.path().toLocal8Bit());
        CompatController controller(inspectExecutable(exe, true));
        controller.setIsolatedPrefix(false);
        QVERIFY(controller.canAttempt());
        controller.launchWithWine();
        QTRY_COMPARE_WITH_TIMEOUT(controller.launchStatus(), QStringLiteral("failed"), 5000);
        QVERIFY(controller.launchMessage().contains(QStringLiteral("exited with code 7")));
        QVERIFY(controller.launchMessage().contains(QStringLiteral("synthetic Wine failure")));
        QVERIFY(QFileInfo::exists(controller.launchLogPath()));
        qputenv("PATH", oldPath);
    }
};

QTEST_GUILESS_MAIN(CompatibilityTest)
#include "compatibility_test.moc"
