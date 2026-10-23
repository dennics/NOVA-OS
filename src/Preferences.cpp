#include "Preferences.hpp"
#include <KConfigGroup>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QStringList>

namespace {
const QStringList profiles{QStringLiteral("minimal"), QStringLiteral("balanced"), QStringLiteral("cinematic")};
bool validAccent(const QString &accent)
{
    static const QRegularExpression pattern(QStringLiteral("^#[0-9a-fA-F]{6}$"));
    return pattern.match(accent).hasMatch();
}
}

Preferences::Preferences(QObject *parent, QString configPath, bool updateDesktop)
    : QObject(parent), m_config(KSharedConfig::openConfig(configPath.isEmpty() ? QStringLiteral("novarc") : configPath)),
      m_updateDesktop(updateDesktop)
{
    KConfigGroup appearance(m_config, QStringLiteral("Appearance"));
    const auto accent = appearance.readEntry("Accent", m_accent);
    if (validAccent(accent)) m_accent = accent.toLower();
    const auto motion = appearance.readEntry("MotionProfile", m_motion);
    if (profiles.contains(motion)) m_motion = motion;
    m_reduced = appearance.readEntry("ReducedMotion", false);
    KConfigGroup general(m_config, QStringLiteral("General"));
    const auto language = general.readEntry("Language", m_language);
    if (language == QStringLiteral("ro") || language == QStringLiteral("en")) m_language = language;
    m_welcome = general.readEntry("WelcomeCompleted", false);
}

void Preferences::save()
{
    KConfigGroup appearance(m_config, QStringLiteral("Appearance"));
    appearance.writeEntry("Accent", m_accent);
    appearance.writeEntry("MotionProfile", m_motion);
    appearance.writeEntry("ReducedMotion", m_reduced);
    KConfigGroup general(m_config, QStringLiteral("General"));
    general.writeEntry("Language", m_language);
    general.writeEntry("WelcomeCompleted", m_welcome);
    m_config->sync();
    emit changed();
}

void Preferences::setAccent(const QString &accent)
{
    if (!validAccent(accent) || accent.toLower() == m_accent) return;
    m_accent = accent.toLower();
    save();
    if (m_updateDesktop) applyAccent();
}
void Preferences::setMotionProfile(const QString &profile)
{
    if (!profiles.contains(profile) || profile == m_motion) return;
    m_motion = profile;
    save();
    if (m_updateDesktop) applyMotion();
}
void Preferences::setReducedMotion(bool reduced)
{
    if (m_reduced == reduced) return;
    m_reduced = reduced;
    save();
    if (m_updateDesktop) applyMotion();
}
void Preferences::setLanguage(const QString &language)
{
    if ((language != QStringLiteral("ro") && language != QStringLiteral("en")) || m_language == language) return;
    m_language = language;
    save();
    if (m_updateDesktop) applyLanguage();
}
void Preferences::completeWelcome()
{
    if (m_welcome) return;
    m_welcome = true;
    save();
    if (m_updateDesktop) {
        applyLanguage();
        applyMotion();
        applyAccent();
    }
}
void Preferences::initializeSession(bool minimalEffects)
{
    // The Live account is temporary; this preference cannot migrate to an installed user.
    if (minimalEffects) {
        m_motion = QStringLiteral("minimal");
        m_reduced = true;
        save();
    }
    if (m_updateDesktop) {
        applyLanguage();
        applyMotion();
    }
}
void Preferences::applyLanguage()
{
    auto locale = KSharedConfig::openConfig(QStringLiteral("plasma-localerc"));
    KConfigGroup(locale, QStringLiteral("Translations")).writeEntry("LANGUAGE", m_language);
    locale->sync();
}
void Preferences::useNovaSounds()
{
    if (!m_updateDesktop) return;
    auto globals = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
    KConfigGroup(globals, QStringLiteral("Sounds")).writeEntry("Theme", "Nova");
    globals->sync();
    emit changed();
}
void Preferences::applyMotion()
{
    auto globals = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
    KConfigGroup(globals, QStringLiteral("KDE")).writeEntry("AnimationDurationFactor", animationsEnabled() ? 1.0 : 0.0);
    globals->sync();
    auto kwin = KSharedConfig::openConfig(QStringLiteral("kwinrc"));
    KConfigGroup(kwin, QStringLiteral("Plugins")).writeEntry("blurEnabled", animationsEnabled());
    kwin->sync();
    QDBusInterface compositor(QStringLiteral("org.kde.KWin"), QStringLiteral("/KWin"),
                              QStringLiteral("org.kde.KWin"), QDBusConnection::sessionBus());
    if (compositor.isValid()) compositor.asyncCall(QStringLiteral("reconfigure"));
}
void Preferences::applyAccent()
{
    // Serialize desktop updates so a fast sequence of clicks always applies the last color.
    if (m_accentProcess) return;
    const auto executable = QStandardPaths::findExecutable(QStringLiteral("plasma-apply-colorscheme"));
    if (executable.isEmpty()) {
        m_desktopError = QStringLiteral("Desktop color integration is unavailable.");
        emit desktopErrorChanged();
        return;
    }
    auto *process = new QProcess(this);
    m_accentProcess = process;
    emit desktopBusyChanged();
    const auto requestedAccent = m_accent;
    connect(process, &QProcess::errorOccurred, this, [this, process](QProcess::ProcessError error) {
        m_desktopError = process->errorString();
        emit desktopErrorChanged();
        if (error == QProcess::FailedToStart) {
            m_accentProcess = nullptr;
            process->deleteLater();
            emit desktopBusyChanged();
        }
    });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, requestedAccent](int code, QProcess::ExitStatus status) {
                m_accentProcess = nullptr;
                m_desktopError = code == 0 && status == QProcess::NormalExit
                    ? QString{} : QString::fromUtf8(process->readAllStandardError()).trimmed();
                if ((code != 0 || status != QProcess::NormalExit) && m_desktopError.isEmpty())
                    m_desktopError = QStringLiteral("Desktop color integration failed.");
                emit desktopErrorChanged();
                process->deleteLater();
                if (requestedAccent != m_accent) applyAccent();
                emit desktopBusyChanged();
            });
    process->start(executable, {QStringLiteral("--accent-color"), m_accent, QStringLiteral("NovaDark")});
}
