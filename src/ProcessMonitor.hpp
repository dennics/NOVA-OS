#pragma once
#include <QObject>
#include <QTimer>
#include <QHash>
#include <QVariantList>
#include <optional>

struct ProcessSnapshot {
    int pid = 0;
    QString name;
    QString state;
    quint64 ticks = 0;
    quint64 startTime = 0;
    quint64 memoryBytes = 0;
    uint uid = 0;
};
std::optional<ProcessSnapshot> decodeProcessStat(const QByteArray &stat, qint64 pageSize);

class ProcessMonitor final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(QVariantList processes READ processes NOTIFY changed)
    Q_PROPERTY(int processCount READ processCount NOTIFY changed)
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY changed)
    Q_PROPERTY(QString sortBy READ sortBy WRITE setSortBy NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
    Q_PROPERTY(qulonglong sampleCount READ sampleCount NOTIFY changed)
public:
    explicit ProcessMonitor(QObject *parent = nullptr, QString procRoot = QStringLiteral("/proc"));
    bool active() const { return m_timer.isActive(); }
    void setActive(bool value);
    QVariantList processes() const { return m_visible; }
    int processCount() const { return m_rows.size(); }
    QString query() const { return m_query; }
    void setQuery(const QString &query);
    QString sortBy() const { return m_sort; }
    void setSortBy(const QString &sort);
    QString message() const { return m_message; }
    qulonglong sampleCount() const { return m_samples; }
    Q_INVOKABLE bool endProcess(int pid, const QString &startTime);
signals:
    void activeChanged();
    void changed();
private:
    void sample();
    void rebuild();
    QString m_procRoot;
    QTimer m_timer;
    QHash<int, ProcessSnapshot> m_previous;
    quint64 m_totalTicks = 0;
    qulonglong m_samples = 0;
    QVariantList m_rows;
    QVariantList m_visible;
    QString m_query;
    QString m_sort = QStringLiteral("cpu");
    QString m_message;
};
