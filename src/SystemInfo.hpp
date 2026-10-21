#pragma once
#include <QObject>
#include <QProcess>
#include <QString>

class SystemInfo final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString cpuName READ cpuName CONSTANT)
    Q_PROPERTY(QString kernel READ kernel CONSTANT)
    Q_PROPERTY(QString operatingSystem READ operatingSystem CONSTANT)
    Q_PROPERTY(QString memoryCapacity READ memoryCapacity CONSTANT)
    Q_PROPERTY(QString selinux READ selinux NOTIFY statusChanged)
    Q_PROPERTY(QString firewall READ firewall NOTIFY statusChanged)
    Q_PROPERTY(bool liveSession READ liveSession CONSTANT)
    Q_PROPERTY(QString updateChannel READ updateChannel CONSTANT)
public:
    explicit SystemInfo(QObject *parent = nullptr);
    QString cpuName() const { return m_cpu; }
    QString kernel() const { return m_kernel; }
    QString operatingSystem() const { return m_os; }
    QString memoryCapacity() const { return m_memory; }
    QString selinux() const { return m_selinux; }
    QString firewall() const { return m_firewall; }
    bool liveSession() const { return m_live; }
    QString updateChannel() const { return m_updateChannel; }
    Q_INVOKABLE void refreshStatus();
signals:
    void statusChanged();
private:
    QString m_cpu, m_kernel, m_os, m_memory, m_selinux, m_updateChannel;
    QString m_firewall = QStringLiteral("unknown");
    bool m_live = false;
    QProcess m_firewallProbe;
};

