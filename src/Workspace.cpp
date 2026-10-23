#include "Workspace.hpp"
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QSet>
#include <QStandardPaths>
#include <QStorageInfo>

namespace {
struct Folder { const char *id; const char *icon; QStandardPaths::StandardLocation location; };
const Folder locations[]{
    {"home", "user-home", QStandardPaths::HomeLocation},
    {"desktop", "user-desktop", QStandardPaths::DesktopLocation},
    {"documents", "folder-documents", QStandardPaths::DocumentsLocation},
    {"downloads", "folder-downloads", QStandardPaths::DownloadLocation},
    {"pictures", "folder-pictures", QStandardPaths::PicturesLocation},
    {"music", "folder-music", QStandardPaths::MusicLocation},
    {"videos", "folder-videos", QStandardPaths::MoviesLocation}
};
}
Workspace::Workspace(QObject *parent) : QObject(parent) { refresh(); }
void Workspace::refresh()
{
    m_folders.clear();
    m_volumes.clear();
    m_message.clear();
    for (const auto &folder : locations) {
        const auto path = QStandardPaths::writableLocation(folder.location);
        if (!path.isEmpty()) m_folders.append(QVariantMap{{"id", folder.id}, {"icon", folder.icon},
            {"path", path}, {"available", QDir(path).exists()}});
    }
    QSet<QByteArray> devices;
    const auto addVolume = [this, &devices](const QStorageInfo &storage, bool system = false) {
        if (!storage.isValid() || !storage.isReady() || storage.bytesTotal() <= 0 || devices.contains(storage.device())) return;
        devices.insert(storage.device());
        m_volumes.append(QVariantMap{{"path", system ? QStringLiteral("/") : storage.rootPath()}, {"name", system ? QStringLiteral("NOVA System") : storage.displayName()},
            {"fileSystem", QString::fromUtf8(storage.fileSystemType())}, {"readOnly", storage.isReadOnly()},
            {"totalGiB", storage.bytesTotal() / 1073741824.0}, {"freeGiB", storage.bytesAvailable() / 1073741824.0},
            {"usedPercent", 100.0 * (storage.bytesTotal() - storage.bytesAvailable()) / storage.bytesTotal()}});
    };
    // An immutable / may be a composefs/overlay view; report the backing system
    // filesystem's capacity while opening the normal root in the file manager.
    addVolume(QDir(QStringLiteral("/sysroot/ostree")).exists() ? QStorageInfo(QStringLiteral("/sysroot")) : QStorageInfo::root(), true);
    addVolume(QStorageInfo(QDir::homePath()));
    for (const auto &volume : QStorageInfo::mountedVolumes()) {
        if (volume.rootPath().startsWith("/run/media/") || volume.rootPath().startsWith("/media/") || volume.rootPath().startsWith("/mnt/")) addVolume(volume);
    }
    emit changed();
}
bool Workspace::open(const QString &path)
{
    const auto program = QStandardPaths::findExecutable(QStringLiteral("dolphin"));
    const auto resolved = QFileInfo(path).canonicalFilePath();
    const bool success = !program.isEmpty() && !resolved.isEmpty() && QDir(resolved).exists()
        && QProcess::startDetached(program, {QStringLiteral("--"), resolved});
    m_message = success ? QString{} : QStringLiteral("This folder is unavailable. It may not have been created or the device may have been disconnected.");
    emit changed();
    return success;
}
bool Workspace::openFolder(const QString &id)
{
    for (const auto &folder : m_folders) if (folder.toMap().value("id") == id) return open(folder.toMap().value("path").toString());
    return false;
}
bool Workspace::openVolume(const QString &path)
{
    refresh(); // A drive may have been unplugged since the page was opened.
    for (const auto &volume : m_volumes) if (volume.toMap().value("path") == path) return open(path);
    return false;
}
