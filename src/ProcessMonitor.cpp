#include "ProcessMonitor.hpp"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <algorithm>
#include <cerrno>
#include <cstring>
#ifdef Q_OS_LINUX
#include <csignal>
#include <unistd.h>
#include <sys/syscall.h>
#endif

namespace {
QByteArray readProc(const QString &path) { QFile file(path); return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray{}; }
}
std::optional<ProcessSnapshot> decodeProcessStat(const QByteArray &stat, qint64 pageSize)
{
    const auto first = stat.indexOf('(');
    const auto last = stat.lastIndexOf(')');
    if (first < 1 || last <= first || pageSize <= 0) return {};
    const auto fields = stat.mid(last + 1).simplified().split(' ');
    if (fields.size() < 22) return {};
    bool okPid, okUser, okSystem, okStart, okRss;
    ProcessSnapshot result;
    result.pid = stat.left(first).trimmed().toInt(&okPid);
    result.name = QString::fromUtf8(stat.mid(first + 1, last - first - 1));
    result.state = QString::fromLatin1(fields[0]);
    const auto user = fields[11].toULongLong(&okUser);
    const auto system = fields[12].toULongLong(&okSystem);
    result.startTime = fields[19].toULongLong(&okStart);
    const auto rss = fields[21].toLongLong(&okRss);
    if (!okPid || result.pid <= 0 || !okUser || !okSystem || !okStart || !okRss || rss < 0) return {};
    result.ticks = user + system;
    result.memoryBytes = static_cast<quint64>(rss) * pageSize;
    return result;
}
ProcessMonitor::ProcessMonitor(QObject *parent, QString procRoot) : QObject(parent), m_procRoot(std::move(procRoot))
{
    m_timer.setInterval(2000);
    connect(&m_timer, &QTimer::timeout, this, &ProcessMonitor::sample);
}
void ProcessMonitor::setActive(bool value)
{
    if (value == active()) return;
    if (value) { m_previous.clear(); m_totalTicks = 0; sample(); m_timer.start(); }
    else m_timer.stop();
    emit activeChanged();
}
void ProcessMonitor::setQuery(const QString &query) { if (m_query != query) { m_query = query.left(160); rebuild(); } }
void ProcessMonitor::setSortBy(const QString &sort)
{
    if (sort != "cpu" && sort != "memory" && sort != "name") return;
    m_sort = sort;
    rebuild();
}
void ProcessMonitor::sample()
{
    quint64 totalTicks = 0;
    auto cpu = readProc(m_procRoot + "/stat").split('\n').value(0).simplified().split(' ');
    if (cpu.value(0) == "cpu" && cpu.size() >= 9) {
        // Guest time is already included in user/nice, so count only the first eight counters.
        for (int i = 1; i <= 8; ++i) totalTicks += cpu[i].toULongLong();
    }
    const auto delta = totalTicks > m_totalTicks ? totalTicks - m_totalTicks : 0;
    QHash<int, ProcessSnapshot> current;
    m_rows.clear();
#ifdef Q_OS_LINUX
    const auto pageSize = sysconf(_SC_PAGESIZE);
    const auto ownUid = getuid();
#else
    const qint64 pageSize = 4096;
    const uint ownUid = 0;
#endif
    for (const auto &entry : QDir(m_procRoot).entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        bool numeric;
        const int pid = entry.toInt(&numeric);
        if (!numeric || pid <= 0) continue;
        auto snapshot = decodeProcessStat(readProc(m_procRoot + "/" + entry + "/stat"), pageSize);
        if (!snapshot || snapshot->pid != pid) continue;
        snapshot->uid = QFileInfo(m_procRoot + "/" + entry).ownerId();
        double cpuPercent = 0;
        bool cpuValid = false;
        const auto previous = m_previous.constFind(pid);
        if (delta && previous != m_previous.cend() && previous->startTime == snapshot->startTime && snapshot->ticks >= previous->ticks) {
            cpuPercent = std::clamp(100.0 * (snapshot->ticks - previous->ticks) / delta, 0.0, 100.0);
            cpuValid = true;
        }
        m_rows.append(QVariantMap{{"pid", pid}, {"name", snapshot->name}, {"state", snapshot->state},
            {"cpu", cpuPercent}, {"cpuValid", cpuValid}, {"memoryMiB", snapshot->memoryBytes / 1048576.0},
            {"startTime", QString::number(snapshot->startTime)},
            {"canEnd", snapshot->uid == ownUid && pid > 1 && pid != QCoreApplication::applicationPid()}});
        current.insert(pid, *snapshot);
    }
    m_previous = std::move(current);
    m_totalTicks = totalTicks;
    ++m_samples;
    m_message = m_rows.isEmpty() ? QStringLiteral("Process information is unavailable.") : QString{};
    rebuild();
}
void ProcessMonitor::rebuild()
{
    m_visible.clear();
    for (const auto &row : m_rows) {
        const auto values = row.toMap();
        if (m_query.isEmpty() || values.value("name").toString().contains(m_query, Qt::CaseInsensitive)
            || values.value("pid").toString() == m_query) m_visible.append(row);
    }
    std::stable_sort(m_visible.begin(), m_visible.end(), [this](const QVariant &left, const QVariant &right) {
        const auto a = left.toMap(), b = right.toMap();
        if (m_sort == "name") return QString::localeAwareCompare(a.value("name").toString(), b.value("name").toString()) < 0;
        const auto key = m_sort == "memory" ? QStringLiteral("memoryMiB") : QStringLiteral("cpu");
        if (a.value(key).toDouble() != b.value(key).toDouble()) return a.value(key).toDouble() > b.value(key).toDouble();
        return a.value("memoryMiB").toDouble() > b.value("memoryMiB").toDouble();
    });
    emit changed();
}
bool ProcessMonitor::endProcess(int pid, const QString &startTime)
{
#ifdef Q_OS_LINUX
    // pidfd binds the request to one process, including if the PID is reused mid-request.
    if (m_procRoot != "/proc" || pid <= 1 || pid == QCoreApplication::applicationPid()) return false;
    const int fd = static_cast<int>(syscall(SYS_pidfd_open, pid, 0));
    if (fd < 0) { m_message = QStringLiteral("This process has exited or cannot be opened."); emit changed(); return false; }
    const auto path = QStringLiteral("/proc/%1").arg(pid);
    const auto snapshot = decodeProcessStat(readProc(path + "/stat"), sysconf(_SC_PAGESIZE));
    bool success = false;
    if (snapshot && snapshot->startTime == startTime.toULongLong() && QFileInfo(path).ownerId() == getuid())
        success = syscall(SYS_pidfd_send_signal, fd, SIGTERM, nullptr, 0) == 0;
    close(fd);
    m_message = success ? QStringLiteral("Close requested. The application may need a moment to exit.")
                        : QStringLiteral("The process changed or permission was denied. Refresh and try again.");
    emit changed();
    return success;
#else
    Q_UNUSED(pid); Q_UNUSED(startTime);
    return false;
#endif
}
