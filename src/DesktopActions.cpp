#include "DesktopActions.hpp"
#include <QHash>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QStringList>

bool DesktopActions::launch(const QString &action)
{
    static const QHash<QString, QStringList> allowed{
        {QStringLiteral("files"), {QStringLiteral("dolphin")}},
        {QStringLiteral("thispc"), {QStringLiteral("nova-control-center"), QStringLiteral("--page"), QStringLiteral("thispc")}},
        {QStringLiteral("tasks"), {QStringLiteral("nova-control-center"), QStringLiteral("--page"), QStringLiteral("tasks")}},
        {QStringLiteral("notifications"), {QStringLiteral("kcmshell6"), QStringLiteral("kcm_notifications")}},
        {QStringLiteral("soundtheme"), {QStringLiteral("kcmshell6"), QStringLiteral("kcm_soundtheme")}},
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

bool DesktopActions::previewSound(const QString &event)
{
    static const QStringList allowed{QStringLiteral("desktop-login"), QStringLiteral("message-new-instant"),
        QStringLiteral("device-added"), QStringLiteral("complete"), QStringLiteral("dialog-warning")};
    if (!allowed.contains(event)) return false;
    const auto path = QStringLiteral("/usr/share/sounds/Nova/stereo/%1.wav").arg(event);
    const auto player = QStandardPaths::findExecutable(QStringLiteral("pw-play"));
    const bool started = !player.isEmpty() && QFileInfo::exists(path) && QProcess::startDetached(player, {path});
    m_error = started ? QString{} : QStringLiteral("sound-preview");
    emit errorChanged();
    return started;
}

