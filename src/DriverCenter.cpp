#include "DriverCenter.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QVariantMap>

namespace {
QString readText(const QString &path)
{
    QFile file(path);
    return file.open(QIODevice::ReadOnly) ? QString::fromUtf8(file.readAll()).trimmed() : QString{};
}
}

DriverCenter::DriverCenter(QObject *parent) : QObject(parent) { refresh(); }

void DriverCenter::refresh()
{
    m_devices.clear();
    const QDir pci(QStringLiteral("/sys/bus/pci/devices"));
    if (!pci.exists()) {
        m_message = QStringLiteral("PCI device information is unavailable.");
        emit changed();
        return;
    }
    for (const QString &entry : pci.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const QString root = pci.filePath(entry);
        const QString gpuClass = readText(root + QStringLiteral("/class"));
        if (!gpuClass.startsWith(QStringLiteral("0x03"))) continue;
        const QString vendorId = readText(root + QStringLiteral("/vendor")).toLower();
        QString vendor, guidance;
        if (vendorId == QStringLiteral("0x10de")) {
            vendor = QStringLiteral("NVIDIA");
            guidance = QStringLiteral("nouveau is the included open driver. Proprietary driver installation requires a validated source and Secure Boot checks.");
        } else if (vendorId == QStringLiteral("0x1002")) {
            vendor = QStringLiteral("AMD");
            guidance = QStringLiteral("amdgpu is supplied by the Linux image for supported GPUs.");
        } else if (vendorId == QStringLiteral("0x8086")) {
            vendor = QStringLiteral("Intel");
            guidance = QStringLiteral("i915 or xe is supplied by the Linux image for supported GPUs.");
        } else {
            vendor = QStringLiteral("Other");
            guidance = QStringLiteral("Consult the active Linux kernel driver for this GPU.");
        }
        const QFileInfo driver(root + QStringLiteral("/driver"));
        const QString active = driver.isSymLink() ? driver.symLinkTarget().section(QLatin1Char('/'), -1)
                                                 : QStringLiteral("unbound");
        m_devices.append(QVariantMap{
            {QStringLiteral("address"), entry},
            {QStringLiteral("vendor"), vendor},
            {QStringLiteral("deviceId"), readText(root + QStringLiteral("/device"))},
            {QStringLiteral("driver"), active},
            {QStringLiteral("guidance"), guidance}
        });
    }
    m_message = m_devices.isEmpty() ? QStringLiteral("No PCI GPU was detected. This can occur in a VM.") : QString{};
    emit changed();
}
