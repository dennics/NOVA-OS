#pragma once

#include <QObject>
#include <QString>

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
public:
    explicit UpdateManager(QObject *parent = nullptr);
    QString source() const { return m_source; }
    bool sourceReady() const { return m_sourceReady; }
    bool rollbackAvailable() const { return m_rollback; }
    bool staged() const { return m_staged; }
    bool liveSystem() const { return m_live; }
    bool busy() const { return m_process != nullptr; }
    QString message() const { return m_message; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void check();
    Q_INVOKABLE void download();
    Q_INVOKABLE void stage();
    Q_INVOKABLE void rollback();
    Q_INVOKABLE void restart();
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
    bool m_live = false;
};
