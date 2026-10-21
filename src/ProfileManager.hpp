#pragma once

#include <QObject>
#include <QString>

class ProfileManager final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY changed)
    Q_PROPERTY(QString profile READ profile NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
public:
    explicit ProfileManager(QObject *parent = nullptr);
    bool available() const { return m_available; }
    QString profile() const { return m_profile; }
    QString message() const { return m_message; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setProfile(const QString &profile);
signals:
    void changed();
private:
    bool m_available = false;
    QString m_profile;
    QString m_message;
};
