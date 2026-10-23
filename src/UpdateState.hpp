#pragma once
#include <QByteArray>
#include <QString>

struct UpdateState {
    bool valid = false;
    bool installed = false;
    bool readOnly = false;
    bool sourceReady = false;
    bool channelMigration = false;
    bool rollback = false;
    bool staged = false;
    bool downloadOnly = false;
    bool updateAvailable = false;
    bool rollbackQueued = false;
    QString source;
    QString currentVersion;
    QString availableVersion;
    QString stagedVersion;
    QString rollbackVersion;
};

UpdateState decodeUpdateState(const QByteArray &json);
