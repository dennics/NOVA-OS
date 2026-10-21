#include "DesktopActions.hpp"
#include <QHash>
#include <QProcess>
#include <QStandardPaths>
#include <QStringList>

bool DesktopActions::launch(const QString &action)
{
    static const QHash<QString, QStringList> allowed{
        {QStringLiteral("files"), {QStringLiteral("dolphin")}},
        {QStringLiteral("apps"), {QStringLiteral("plasma-discover")}},
        {QStringLiteral("browser"), {QStringLiteral("opera-gx")}},
        {QStringLiteral("settings"), {QStringLiteral("systemsettings")}},
        {QStringLiteral("display"), {QStringLiteral("kcmshell6"), QStringLiteral("kcm_kscreen")}},
        {QStringLiteral("sound"), {QStringLiteral("kcmshell6"), QStringLiteral("kcm_pulseaudio")}},
        {QStringLiteral("network"), {QStringLiteral("kcmshell6"), QStringLiteral("kcm_networkmanagement")}},
        {QStringLiteral("bluetooth"), {QStringLiteral("kcmshell6"), QStringLiteral("kcm_bluetooth")}},
        {QStringLiteral("power"), {QStringLiteral("kcmshell6"), QStringLiteral("kcm_powerdevilprofilesconfig")}},
        {QStringLiteral("accessibility"), {QStringLiteral("kcmshell6"), QStringLiteral("kcm_access")}},
    };
    if (!allowed.contains(action)) return false;
    auto arguments = allowed.value(action);
    const auto program = QStandardPaths::findExecutable(arguments.takeFirst());
    const auto started = !program.isEmpty() && QProcess::startDetached(program, arguments);
    m_error = started ? QString{} : action;
    emit errorChanged();
    return started;
}

