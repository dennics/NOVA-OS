#include "CompatController.hpp"

#include <QDesktopServices>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
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
    if (!canAttempt() || (m_wineProcess && m_wineProcess->state() != QProcess::NotRunning)) return;
    // Recheck immediately before launching: the file may have disappeared while
    // the assessment window was open. Wine receives one literal path argument.
    const QFileInfo executable(m_report.path);
    const QString wine = QStandardPaths::findExecutable(QStringLiteral("wine"));
    if (!executable.isFile() || !executable.isReadable() || wine.isEmpty()) {
        m_launchStatus = QStringLiteral("unavailable");
        m_launchMessage = QStringLiteral("The executable or Wine is unavailable. Check that Wine is installed and try again.");
    } else {
        const QString appData = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
        const QString logDirectory = appData + QStringLiteral("/wine-logs");
        if (appData.isEmpty() || !QDir().mkpath(logDirectory)) {
            m_launchStatus = QStringLiteral("failed");
            m_launchMessage = QStringLiteral("Could not create NOVA's Wine log folder in your home directory.");
            emit launchStatusChanged();
            return;
        }
        m_launchLogPath = logDirectory + QStringLiteral("/launch-%1.log")
            .arg(QDateTime::currentDateTimeUtc().toString(QStringLiteral("yyyyMMdd-HHmmss-zzz")));
        auto *process = new QProcess(this);
        m_wineProcess = process;
        process->setProgram(wine);
        process->setArguments({executable.absoluteFilePath()});
        process->setWorkingDirectory(executable.absolutePath());
        const QString stdoutPath = m_launchLogPath + QStringLiteral(".stdout");
        const QString stderrPath = m_launchLogPath + QStringLiteral(".stderr");
        process->setStandardOutputFile(stdoutPath, QIODevice::Truncate);
        process->setStandardErrorFile(stderrPath, QIODevice::Truncate);
        if (m_isolatedPrefix) {
            const QString hash = QString::fromLatin1(QCryptographicHash::hash(
                executable.canonicalFilePath().toUtf8(), QCryptographicHash::Sha256).toHex().left(20));
            const QString root = appData + QStringLiteral("/wine-prefixes/") + hash;
            if (!QDir().mkpath(root)) {
                m_wineProcess = nullptr;
                process->deleteLater();
                m_launchStatus = QStringLiteral("failed");
                m_launchMessage = QStringLiteral("Could not create this program's separate Wine environment.");
                emit launchStatusChanged();
                return;
            }
            auto environment = QProcessEnvironment::systemEnvironment();
            environment.insert(QStringLiteral("WINEPREFIX"), root);
            process->setProcessEnvironment(environment);
        }
        connect(process, &QProcess::started, this, [this, process] {
            // The Windows application must keep running if the compatibility
            // window is closed. The log is redirected to disk, so the detached
            // process cannot block on a full pipe.
            process->setParent(nullptr);
            m_launchStatus = QStringLiteral("running");
            m_launchMessage = QStringLiteral("Wine started the process. This does not guarantee that the Windows program is compatible.");
            emit launchStatusChanged();
        });
        connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
                [this, process](int code, QProcess::ExitStatus status) {
            QFile stdoutLog(m_launchLogPath + QStringLiteral(".stdout"));
            QFile stderrLog(m_launchLogPath + QStringLiteral(".stderr"));
            QByteArray bytes;
            if (stdoutLog.open(QIODevice::ReadOnly)) bytes += stdoutLog.readAll();
            if (stderrLog.open(QIODevice::ReadOnly)) bytes += stderrLog.readAll();
            if (bytes.size() > 2400) bytes = bytes.right(2400);
            const QString detail = QString::fromLocal8Bit(bytes).trimmed();
            QFile summary(m_launchLogPath);
            if (summary.open(QIODevice::WriteOnly | QIODevice::Truncate)) summary.write(bytes);
            m_wineProcess = nullptr;
            m_launchStatus = status == QProcess::NormalExit && code == 0
                ? QStringLiteral("finished") : QStringLiteral("failed");
            m_launchMessage = status == QProcess::NormalExit
                ? QStringLiteral("Wine exited with code %1.").arg(code)
                : QStringLiteral("Wine stopped unexpectedly.");
            if (!detail.isEmpty()) m_launchMessage += QStringLiteral("\n") + detail;
            emit launchStatusChanged();
            process->deleteLater();
        });
        connect(process, &QProcess::errorOccurred, this, [this, process](QProcess::ProcessError error) {
            if (error != QProcess::FailedToStart) return;
            m_wineProcess = nullptr;
            m_launchStatus = QStringLiteral("failed");
            m_launchMessage = process->errorString();
            emit launchStatusChanged();
            process->deleteLater();
        });
        m_launchStatus = QStringLiteral("starting");
        m_launchMessage = QStringLiteral("Starting Wine…");
        process->start();
    }
    emit launchStatusChanged();
}

void CompatController::openNativePage()
{
    if (m_report.nativeUrl.isEmpty()) return;
    QDesktopServices::openUrl(QUrl(m_report.nativeUrl));
}

