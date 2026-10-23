#include "UpdateState.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>

UpdateState decodeUpdateState(const QByteArray &json)
{
    UpdateState result;
    QJsonParseError error;
    const auto document = QJsonDocument::fromJson(json, &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) return result;
    const auto root = document.object();
    if (!root.value("status").isObject() || !root.value("spec").isObject()) return result;
    result.valid = true;
    const auto status = root.value("status").toObject();
    const auto image = root.value("spec").toObject().value("image").toObject();
    const auto booted = status.value("booted").toObject();
    const auto staged = status.value("staged").toObject();
    const auto previous = status.value("rollback").toObject();
    result.installed = !booted.isEmpty();
    result.readOnly = status.value("readOnly").toBool();
    result.source = image.value("image").toString();
    result.rollback = !previous.isEmpty();
    result.rollbackQueued = result.rollback && root.value("spec").toObject().value("bootOrder") == "rollback";
    result.staged = !staged.isEmpty();
    result.downloadOnly = staged.value("downloadOnly").toBool();
    const auto currentImage = booted.value("image").toObject();
    const auto cached = booted.value("cachedUpdate").toObject();
    result.currentVersion = currentImage.value("version").toString();
    result.availableVersion = cached.value("version").toString();
    result.stagedVersion = staged.value("image").toObject().value("version").toString();
    result.rollbackVersion = previous.value("image").toObject().value("version").toString();
    const auto currentDigest = currentImage.value("imageDigest").toString();
    const auto cachedDigest = cached.value("imageDigest").toString();
    result.updateAvailable = !cachedDigest.isEmpty() && !currentDigest.isEmpty() && cachedDigest != currentDigest;
    result.sourceReady = result.installed && !result.readOnly && image.value("transport") == "registry"
        && !result.source.isEmpty() && !result.source.startsWith("localhost/") && !result.source.startsWith("nova.invalid/");
    static const QRegularExpression oldNova(QStringLiteral("^(?:ghcr\\.io/dennics/nova-os:0\\.[0-9]+(?:\\.[0-9]+)?-preview|nova\\.invalid/nova:preview|localhost/nova:[a-zA-Z0-9._-]+)$"));
    result.channelMigration = result.installed && !result.readOnly && oldNova.match(result.source).hasMatch();
    return result;
}
