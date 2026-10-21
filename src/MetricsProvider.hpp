#pragma once
#include "core/SystemMetrics.hpp"
#include <QObject>
#include <QTimer>
#include <QString>

class MetricsProvider final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool cpuValid READ cpuValid NOTIFY sampleChanged)
    Q_PROPERTY(double cpuPercent READ cpuPercent NOTIFY sampleChanged)
    Q_PROPERTY(bool memoryValid READ memoryValid NOTIFY sampleChanged)
    Q_PROPERTY(double memoryUsedGiB READ memoryUsedGiB NOTIFY sampleChanged)
    Q_PROPERTY(double memoryTotalGiB READ memoryTotalGiB NOTIFY sampleChanged)
    Q_PROPERTY(double memoryPercent READ memoryPercent NOTIFY sampleChanged)
    Q_PROPERTY(qulonglong sampleCount READ sampleCount NOTIFY sampleChanged)
public:
    explicit MetricsProvider(QObject *parent = nullptr, QString procRoot = QStringLiteral("/proc"));
    bool active() const { return m_timer.isActive(); }
    void setActive(bool active);
    bool cpuValid() const { return m_cpu.has_value(); }
    double cpuPercent() const { return m_cpu.value_or(0.0); }
    bool memoryValid() const { return m_memory.has_value(); }
    double memoryUsedGiB() const;
    double memoryTotalGiB() const;
    double memoryPercent() const;
    qulonglong sampleCount() const { return m_sampleCount; }
signals:
    void activeChanged();
    void sampleChanged();
private:
    void sample();
    QString m_procRoot;
    QTimer m_timer;
    std::optional<nova::CpuTimes> m_previous;
    std::optional<nova::Memory> m_memory;
    std::optional<double> m_cpu;
    qulonglong m_sampleCount = 0;
};

