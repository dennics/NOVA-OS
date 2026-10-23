#pragma once

#include <QObject>
#include <QString>
#include "UpdateState.hpp"

class QProcess;

class UpdateManager final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString source READ source NOTIFY changed)
    Q_PROPERTY(bool sourceReady READ sourceReady NOTIFY changed)
    Q_PROPERTY(bool rollbackAvailable READ rollbackAvailable NOTIFY changed)
    Q_PROPERTY(bool staged READ staged NOTIFY changed)
    Q_PROPERTY(bool liveSystem READ liveSystem NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
    Q_PROPERTY(QString currentVersion READ currentVersion NOTIFY changed)
    Q_PROPERTY(QString availableVersion READ availableVersion NOTIFY changed)
    Q_PROPERTY(QString stagedVersion READ stagedVersion NOTIFY changed)
    Q_PROPERTY(QString rollbackVersion READ rollbackVersion NOTIFY changed)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY changed)
    Q_PROPERTY(bool downloadOnly READ downloadOnly NOTIFY changed)
    Q_PROPERTY(bool channelMigrationAvailable READ channelMigrationAvailable NOTIFY changed)
    Q_PROPERTY(QString details READ details NOTIFY changed)
    Q_PROPERTY(QString operation READ operation NOTIFY changed)
    Q_PROPERTY(bool restartRequired READ restartRequired NOTIFY changed)
public:
    explicit UpdateManager(QObject *parent = nullptr);
    QString source() const { return m_source; }
    bool sourceReady() const { return m_sourceReady; }
    bool rollbackAvailable() const { return m_rollback; }
    bool staged() const { return m_staged; }
    bool liveSystem() const { return m_live; }
    bool busy() const { return m_process != nullptr; }
    QString message() const { return m_message; }
    QString currentVersion() const { return m_state.currentVersion; }
    QString availableVersion() const { return m_state.availableVersion; }
    QString stagedVersion() const { return m_state.stagedVersion; }
    QString rollbackVersion() const { return m_state.rollbackVersion; }
    bool updateAvailable() const { return m_state.updateAvailable; }
    bool downloadOnly() const { return m_state.downloadOnly; }
    bool channelMigrationAvailable() const { return m_state.channelMigration; }
    QString details() const { return m_details; }
    QString operation() const { return m_operation; }
    bool restartRequired() const { return (m_state.staged && !m_state.downloadOnly) || m_state.rollbackQueued; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void check();
    Q_INVOKABLE void download();
    Q_INVOKABLE void stage();
    Q_INVOKABLE void rollback();
    Q_INVOKABLE void restart();
    Q_INVOKABLE void install();
    Q_INVOKABLE void enablePreviewChannel();
signals:
    void changed();
private:
    void runOperation(const QString &verb);
    void parseStatus(const QByteArray &output);
    QProcess *m_process = nullptr;
    QString m_source;
    QString m_message;
    bool m_sourceReady = false;
    bool m_rollback = false;
    bool m_staged = false;
    bool m_live = true;
    UpdateState m_state;
    QString m_details;
    QString m_operation;
};
