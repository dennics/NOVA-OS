#include "MetricsProvider.hpp"
#include <QFile>

namespace {
QByteArray contents(const QString &path)
{
    QFile file(path);
    return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray{};
}
constexpr double gibibyte = 1024.0 * 1024.0 * 1024.0;
}

MetricsProvider::MetricsProvider(QObject *parent, QString procRoot)
    : QObject(parent), m_procRoot(std::move(procRoot))
{
    m_timer.setInterval(1000);
    connect(&m_timer, &QTimer::timeout, this, &MetricsProvider::sample);
}

void MetricsProvider::setActive(bool active)
{
    if (active == m_timer.isActive()) return;
    m_previous.reset();
    m_cpu.reset();
    if (active) {
        m_timer.start();
        sample();
    } else {
        m_timer.stop();
    }
    emit activeChanged();
    emit sampleChanged();
}

void MetricsProvider::sample()
{
    if (!m_timer.isActive()) return;
    const auto cpuText = contents(m_procRoot + QStringLiteral("/stat"));
    const auto memoryText = contents(m_procRoot + QStringLiteral("/meminfo"));
    const auto cpu = nova::parseCpuStat(std::string_view(cpuText.constData(), cpuText.size()));
    m_cpu = cpu && m_previous ? nova::cpuUsage(*m_previous, *cpu) : std::nullopt;
    m_previous = cpu;
    m_memory = nova::parseMemInfo(std::string_view(memoryText.constData(), memoryText.size()));
    ++m_sampleCount;
    emit sampleChanged();
}

double MetricsProvider::memoryUsedGiB() const
{
    return m_memory ? static_cast<double>(m_memory->usedBytes()) / gibibyte : 0.0;
}
double MetricsProvider::memoryTotalGiB() const
{
    return m_memory ? static_cast<double>(m_memory->totalBytes) / gibibyte : 0.0;
}
double MetricsProvider::memoryPercent() const
{
    return m_memory ? 100.0 * static_cast<double>(m_memory->usedBytes()) / static_cast<double>(m_memory->totalBytes) : 0.0;
}

