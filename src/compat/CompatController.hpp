#pragma once

#include "CompatInspector.hpp"
#include <QObject>

class QProcess;

class CompatController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString fileName READ fileName CONSTANT)
    Q_PROPERTY(QString filePath READ filePath CONSTANT)
    Q_PROPERTY(QString architecture READ architecture CONSTANT)
    Q_PROPERTY(QString productName READ productName CONSTANT)
    Q_PROPERTY(QString nativeName READ nativeName CONSTANT)
    Q_PROPERTY(QString nativeUrl READ nativeUrl CONSTANT)
    Q_PROPERTY(QString problem READ problem CONSTANT)
    Q_PROPERTY(bool validPe READ validPe CONSTANT)
    Q_PROPERTY(bool wineArchitecture READ wineArchitecture CONSTANT)
    Q_PROPERTY(bool wineInstalled READ wineInstalled CONSTANT)
    Q_PROPERTY(bool canAttempt READ canAttempt CONSTANT)
    Q_PROPERTY(bool romanian READ romanian CONSTANT)
    Q_PROPERTY(QString launchStatus READ launchStatus NOTIFY launchStatusChanged)
    Q_PROPERTY(QString launchMessage READ launchMessage NOTIFY launchStatusChanged)
    Q_PROPERTY(QString launchLogPath READ launchLogPath NOTIFY launchStatusChanged)
    Q_PROPERTY(bool isolatedPrefix READ isolatedPrefix WRITE setIsolatedPrefix NOTIFY isolatedPrefixChanged)

public:
    explicit CompatController(const CompatReport &report, QObject *parent = nullptr);
    QString fileName() const { return m_report.fileName; }
    QString filePath() const { return m_report.path; }
    QString architecture() const { return m_report.architecture; }
    QString productName() const { return m_report.productName; }
    QString nativeName() const { return m_report.nativeName; }
    QString nativeUrl() const { return m_report.nativeUrl; }
    QString problem() const { return m_report.problem; }
    bool validPe() const { return m_report.validPe; }
    bool wineArchitecture() const { return m_report.wineArchitecture; }
    bool wineInstalled() const { return m_report.wineInstalled; }
    bool canAttempt() const;
    bool romanian() const;
    QString launchStatus() const { return m_launchStatus; }
    QString launchMessage() const { return m_launchMessage; }
    QString launchLogPath() const { return m_launchLogPath; }
    bool isolatedPrefix() const { return m_isolatedPrefix; }
    void setIsolatedPrefix(bool value) { if (m_isolatedPrefix != value) { m_isolatedPrefix = value; emit isolatedPrefixChanged(); } }

    Q_INVOKABLE void launchWithWine();
    Q_INVOKABLE void openNativePage();

signals:
    void launchStatusChanged();
    void isolatedPrefixChanged();

private:
    CompatReport m_report;
    QString m_launchStatus;
    QString m_launchMessage;
    QString m_launchLogPath;
    QProcess *m_wineProcess = nullptr;
    bool m_isolatedPrefix = true;
};

