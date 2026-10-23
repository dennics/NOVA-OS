#pragma once
#include <QObject>
#include <QVariantList>

class Workspace final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList folders READ folders NOTIFY changed)
    Q_PROPERTY(QVariantList volumes READ volumes NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
public:
    explicit Workspace(QObject *parent = nullptr);
    QVariantList folders() const { return m_folders; }
    QVariantList volumes() const { return m_volumes; }
    QString message() const { return m_message; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE bool openFolder(const QString &id);
    Q_INVOKABLE bool openVolume(const QString &path);
signals:
    void changed();
private:
    bool open(const QString &path);
    QVariantList m_folders;
    QVariantList m_volumes;
    QString m_message;
};
