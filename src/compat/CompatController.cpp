#include "CompatController.hpp"

#include <QDesktopServices>
#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QLocale>
#include <QProcess>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QUrl>
#include <unistd.h>

CompatController::CompatController(const CompatReport &report, QObject *parent)
    : QObject(parent), m_report(report)
{
}

bool CompatController::canAttempt() const
{
    return m_report.validPe && m_report.wineArchitecture && m_report.wineInstalled && geteuid() != 0;
}

bool CompatController::romanian() const
{
    return QLocale::system().language() == QLocale::Romanian;
}

void CompatController::launchWithWine()
{
    if (!canAttempt()) return;
    // Recheck immediately before launching: the file may have disappeared while
    // the assessment window was open. Wine receives one literal path argument.
    const QFileInfo executable(m_report.path);
    const QString wine = QStandardPaths::findExecutable(QStringLiteral("wine"));
    if (!executable.isFile() || !executable.isReadable() || wine.isEmpty()) {
        m_launchStatus = QStringLiteral("unavailable");
    } else {
        QProcess process;
        process.setProgram(wine);
        process.setArguments({executable.absoluteFilePath()});
        process.setWorkingDirectory(executable.absolutePath());
        if (m_isolatedPrefix) {
            const QString hash = QString::fromLatin1(QCryptographicHash::hash(
                executable.canonicalFilePath().toUtf8(), QCryptographicHash::Sha256).toHex().left(20));
            const QString root = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)
                + QStringLiteral("/wine-prefixes/") + hash;
            if (!QDir().mkpath(root)) {
                m_launchStatus = QStringLiteral("failed");
                emit launchStatusChanged();
                return;
            }
            auto environment = QProcessEnvironment::systemEnvironment();
            environment.insert(QStringLiteral("WINEPREFIX"), root);
            process.setProcessEnvironment(environment);
        }
        m_launchStatus = process.startDetached() ? QStringLiteral("started") : QStringLiteral("failed");
    }
    emit launchStatusChanged();
}

void CompatController::openNativePage()
{
    if (m_report.nativeUrl.isEmpty()) return;
    QDesktopServices::openUrl(QUrl(m_report.nativeUrl));
}

