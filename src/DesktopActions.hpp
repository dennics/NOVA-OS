#pragma once
#include <QObject>
#include <QString>

class DesktopActions final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
public:
    using QObject::QObject;
    QString error() const { return m_error; }
    Q_INVOKABLE bool launch(const QString &action);
signals:
    void errorChanged();
private:
    QString m_error;
};

