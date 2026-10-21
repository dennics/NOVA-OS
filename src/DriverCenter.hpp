#pragma once

#include <QObject>
#include <QVariantList>

class DriverCenter final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList devices READ devices NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
public:
    explicit DriverCenter(QObject *parent = nullptr);
    QVariantList devices() const { return m_devices; }
    QString message() const { return m_message; }
    Q_INVOKABLE void refresh();
signals:
    void changed();
private:
    QVariantList m_devices;
    QString m_message;
};
