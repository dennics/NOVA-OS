#include "UpdateManager.hpp"

#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>

namespace {
constexpr auto helperPath = "/usr/libexec/nova-update-helper";

QString trimmedOutput(const QByteArray &stdoutData, const QByteArray &stderrData)
{
    QString text = QString::fromUtf8(stdoutData + stderrData).trimmed();
    if (text.size() > 650) text = text.left(650) + QStringLiteral("…");
    return text;
}
}

UpdateManager::UpdateManager(QObject *parent) : QObject(parent)
{
    refresh();
}

void UpdateManager::parseStatus(const QByteArray &output)
{
    m_state = decodeUpdateState(output);
    m_source = m_state.source;
    m_sourceReady = m_state.sourceReady;
    m_rollback = m_state.rollback;
    m_staged = m_state.staged;
    m_live = !m_state.installed || m_state.readOnly;
    if (!m_state.valid) {
        m_message = QStringLiteral("bootc returned an unreadable status.");
        return;
    }
    if (!m_state.installed) m_message = QStringLiteral("NOVA is not running from an installed bootc image.");
    else if (m_live) m_message = QStringLiteral("Updates are available after installation, not in Live mode.");
    else if (!m_sourceReady) m_message = QStringLiteral("No NOVA update registry is configured for this preview.");
    else if (m_message.isEmpty()) m_message = QStringLiteral("Image source ready. Check for an update when connected.");
}

void UpdateManager::refresh()
{
    if (busy()) return;
    const QString bootc = QStandardPaths::findExecutable(QStringLiteral("bootc"));
    if (bootc.isEmpty()) {
        m_message = QStringLiteral("bootc is unavailable.");
        emit changed();
        return;
    }
    auto *process = new QProcess(this);
    m_process = process;
    emit changed();
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process](int code, QProcess::ExitStatus status) {
        if (m_process != process) return;
        m_process = nullptr;
        if (status == QProcess::NormalExit && code == 0) parseStatus(process->readAllStandardOutput());
        else m_message = trimmedOutput(process->readAllStandardOutput(), process->readAllStandardError());
        process->deleteLater();
        emit changed();
    });
    connect(process, &QProcess::errorOccurred, this, [this, process] {
        if (m_process != process) return;
        m_process = nullptr;
        m_message = process->errorString();
        process->deleteLater();
        emit changed();
    });
    process->start(bootc, {QStringLiteral("status"), QStringLiteral("--format=json"),
                           QStringLiteral("--format-version=1")});
}

void UpdateManager::runOperation(const QString &verb)
{
    if (busy() || m_live
        || (verb == QStringLiteral("enable-preview") && !m_state.channelMigration)
        || (verb != QStringLiteral("rollback") && verb != QStringLiteral("enable-preview") && !m_sourceReady)
        || (verb == QStringLiteral("rollback") && !m_rollback)) return;
    const QString pkexec = QStandardPaths::findExecutable(QStringLiteral("pkexec"));
    if (pkexec.isEmpty() || !QFileInfo::exists(QString::fromLatin1(helperPath))) {
        m_message = QStringLiteral("NOVA update authorization is unavailable.");
        emit changed();
        return;
    }
    auto *process = new QProcess(this);
    m_process = process;
    m_operation = verb;
    m_details.clear();
    m_message = QStringLiteral("Running %1…").arg(verb);
    emit changed();
    process->setProcessChannelMode(QProcess::MergedChannels);
    connect(process, &QProcess::readyReadStandardOutput, this, [this, process] {
        m_details += QString::fromUtf8(process->readAllStandardOutput());
        if (m_details.size() > 16000) m_details = m_details.right(16000);
        emit changed();
    });
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this, process, verb](int code, QProcess::ExitStatus status) {
        if (m_process != process) return;
        m_process = nullptr;
        m_details += QString::fromUtf8(process->readAllStandardOutput());
        if (m_details.size() > 16000) m_details = m_details.right(16000);
        const QString output = m_details.trimmed().right(650);
        m_operation.clear();
        m_message = status == QProcess::NormalExit && code == 0
            ? (output.isEmpty() ? QStringLiteral("%1 completed.").arg(verb) : output)
            : (output.isEmpty() ? QStringLiteral("%1 failed or authorization was cancelled.").arg(verb) : output);
        process->deleteLater();
        emit changed();
        refresh();
    });
    connect(process, &QProcess::errorOccurred, this, [this, process] {
        if (m_process != process) return;
        m_process = nullptr;
        m_operation.clear();
        m_message = process->errorString();
        process->deleteLater();
        emit changed();
    });
    process->start(pkexec, {QString::fromLatin1(helperPath), verb});
}

void UpdateManager::check() { runOperation(QStringLiteral("check")); }
void UpdateManager::download() { runOperation(QStringLiteral("download")); }
void UpdateManager::stage() { runOperation(QStringLiteral("stage")); }
void UpdateManager::rollback() { runOperation(QStringLiteral("rollback")); }
void UpdateManager::install() { runOperation(QStringLiteral("install")); }
void UpdateManager::enablePreviewChannel() { runOperation(QStringLiteral("enable-preview")); }

void UpdateManager::restart()
{
    if (busy() || m_live) return;
    const QString systemctl = QStandardPaths::findExecutable(QStringLiteral("systemctl"));
    if (systemctl.isEmpty() || !QProcess::startDetached(systemctl, {QStringLiteral("reboot")})) {
        m_message = QStringLiteral("Could not request a restart.");
        emit changed();
    }
}
