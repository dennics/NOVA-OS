#include "SystemInfo.hpp"
#include "core/SystemMetrics.hpp"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSysInfo>

namespace {
QByteArray read(const QString &path)
{
    QFile file(path);
    return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray{};
}
}

SystemInfo::SystemInfo(QObject *parent) : QObject(parent)
{
    m_kernel = QSysInfo::kernelVersion();
    m_os = QSysInfo::prettyProductName();
    const auto release = QJsonDocument::fromJson(read(QStringLiteral("/usr/lib/nova/release.json"))).object();
    if (!release.isEmpty()) m_os = release.value(QStringLiteral("name")).toString() + QStringLiteral(" ") + release.value(QStringLiteral("version")).toString();
    m_updateChannel = release.value(QStringLiteral("updateChannel")).toString();
    const auto cpuInfo = QString::fromUtf8(read(QStringLiteral("/proc/cpuinfo")));
    for (const auto &line : cpuInfo.split(QLatin1Char('\n'))) {
        if (line.startsWith(QStringLiteral("model name"))) {
            m_cpu = line.section(QLatin1Char(':'), 1).simplified();
            break;
        }
    }
    const auto memoryText = read(QStringLiteral("/proc/meminfo"));
    const auto memory = nova::parseMemInfo(std::string_view(memoryText.constData(), memoryText.size()));
    if (memory) m_memory = QString::number(static_cast<double>(memory->totalBytes) / (1024.0 * 1024.0 * 1024.0), 'f', 1) + QStringLiteral(" GiB");
    const auto cmdline = read(QStringLiteral("/proc/cmdline")).simplified().split(' ');
    m_live = cmdline.contains("rd.live.image");
    connect(&m_firewallProbe, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int code, QProcess::ExitStatus status) {
                const auto output = m_firewallProbe.readAllStandardOutput().trimmed();
                m_firewall = QStringLiteral("unknown");
                if (status == QProcess::NormalExit && code == 0 && output == "active")
                    m_firewall = QStringLiteral("active");
                else if (status == QProcess::NormalExit && code == 3 && (output == "inactive" || output == "failed"))
                    m_firewall = QString::fromUtf8(output);
                emit statusChanged();
            });
    connect(&m_firewallProbe, &QProcess::errorOccurred, this, [this] {
        m_firewall = QStringLiteral("unknown");
        emit statusChanged();
    });
    refreshStatus();
}

void SystemInfo::refreshStatus()
{
    const auto enforcement = read(QStringLiteral("/sys/fs/selinux/enforce")).trimmed();
    m_selinux = enforcement == "1" ? QStringLiteral("enforcing") : enforcement == "0" ? QStringLiteral("permissive") : QStringLiteral("unknown");
    emit statusChanged();
    if (m_firewallProbe.state() == QProcess::NotRunning)
        m_firewallProbe.start(QStringLiteral("systemctl"), {QStringLiteral("is-active"), QStringLiteral("firewalld.service")});
}

