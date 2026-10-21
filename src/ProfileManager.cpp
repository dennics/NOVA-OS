#include "ProfileManager.hpp"

#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusReply>
#include <QDBusVariant>

namespace {
constexpr auto service = "net.hadess.PowerProfiles";
constexpr auto path = "/net/hadess/PowerProfiles";
constexpr auto properties = "org.freedesktop.DBus.Properties";
}

ProfileManager::ProfileManager(QObject *parent) : QObject(parent) { refresh(); }

void ProfileManager::refresh()
{
    const auto bus = QDBusConnection::systemBus();
    m_available = bus.isConnected() && bus.interface()
        && bus.interface()->isServiceRegistered(QString::fromLatin1(service));
    m_profile.clear();
    if (m_available) {
        QDBusInterface interface(QString::fromLatin1(service), QString::fromLatin1(path),
                                 QString::fromLatin1(properties), bus);
        const QDBusReply<QDBusVariant> reply = interface.call(QStringLiteral("Get"),
            QString::fromLatin1(service), QStringLiteral("ActiveProfile"));
        if (reply.isValid()) {
            const QString value = reply.value().variant().toString();
            if (value == QStringLiteral("power-saver")) m_profile = QStringLiteral("eco");
            else if (value == QStringLiteral("balanced")) m_profile = QStringLiteral("balanced");
            else if (value == QStringLiteral("performance")) m_profile = QStringLiteral("gaming");
        }
        if (m_profile.isEmpty()) m_message = QStringLiteral("Could not read the active power profile.");
        else m_message.clear();
    } else m_message = QStringLiteral("Power profile service is unavailable on this system.");
    emit changed();
}

void ProfileManager::setProfile(const QString &profile)
{
    if (!m_available) { refresh(); return; }
    QString power;
    if (profile == QStringLiteral("eco")) power = QStringLiteral("power-saver");
    else if (profile == QStringLiteral("balanced")) power = QStringLiteral("balanced");
    else if (profile == QStringLiteral("gaming")) power = QStringLiteral("performance");
    else { m_message = QStringLiteral("Unknown power profile."); emit changed(); return; }
    QDBusInterface interface(QString::fromLatin1(service), QString::fromLatin1(path),
                             QString::fromLatin1(properties), QDBusConnection::systemBus());
    const QDBusReply<void> reply = interface.call(QStringLiteral("Set"), QString::fromLatin1(service),
        QStringLiteral("ActiveProfile"), QVariant::fromValue(QDBusVariant(power)));
    if (!reply.isValid()) {
        m_message = reply.error().message();
        emit changed();
        return;
    }
    refresh();
}
