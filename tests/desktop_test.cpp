#include "ProcessMonitor.hpp"
#include "UpdateState.hpp"
#include "Workspace.hpp"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QTemporaryDir>
#include <QtTest>

class DesktopTest final : public QObject {
    Q_OBJECT
private slots:
    void updateStatusAndMigration()
    {
        const QByteArray json = R"({"spec":{"image":{"image":"ghcr.io/dennics/nova-os:preview","transport":"registry"}},"status":{"readOnly":false,"booted":{"image":{"version":"0.3.0-preview","imageDigest":"sha256:aaa"},"cachedUpdate":{"version":"0.3.1-preview","imageDigest":"sha256:bbb"}},"staged":{"image":{"version":"0.3.1-preview"},"downloadOnly":true},"rollback":{"image":{"version":"0.2.1-preview"}}}})";
        const auto status = decodeUpdateState(json);
        QVERIFY(status.valid);
        QVERIFY(status.sourceReady);
        QVERIFY(status.updateAvailable);
        QVERIFY(status.staged);
        QVERIFY(status.downloadOnly);
        QVERIFY(!status.channelMigration);
        QCOMPARE(status.currentVersion, QStringLiteral("0.3.0-preview"));
        QCOMPARE(status.stagedVersion, QStringLiteral("0.3.1-preview"));
        QCOMPARE(status.rollbackVersion, QStringLiteral("0.2.1-preview"));
        auto old = json;
        old.replace("ghcr.io/dennics/nova-os:preview", "nova.invalid/nova:preview");
        const auto legacy = decodeUpdateState(old);
        QVERIFY(!legacy.sourceReady);
        QVERIFY(legacy.channelMigration);
        old = json;
        old.replace("ghcr.io/dennics/nova-os:preview", "ghcr.io/dennics/nova-os:0.2.1-preview");
        QVERIFY(decodeUpdateState(old).channelMigration);
        old.replace("0.2.1-preview\",\"transport", "preview-unknown\",\"transport");
        QVERIFY(!decodeUpdateState(old).channelMigration);
        old = json;
        old.replace("\"readOnly\":false", "\"readOnly\":true");
        QVERIFY(!decodeUpdateState(old).sourceReady);
        QVERIFY(!decodeUpdateState(old).channelMigration);
        QVERIFY(!decodeUpdateState("not JSON").valid);
        QVERIFY(!decodeUpdateState("{}").valid);
        QVERIFY(!decodeUpdateState(R"({"spec":{},"status":{"booted":null}})").sourceReady);
        auto rollback = QJsonDocument::fromJson(json).object();
        auto spec = rollback.value("spec").toObject();
        spec.insert("bootOrder", "rollback");
        rollback.insert("spec", spec);
        QVERIFY(decodeUpdateState(QJsonDocument(rollback).toJson()).rollbackQueued);
    }
    void processParserHandlesNamesAndUnavailableData()
    {
        QList<QByteArray> fields(22, "0");
        fields[0] = "S"; fields[11] = "10"; fields[12] = "5"; fields[19] = "123456"; fields[21] = "8";
        const auto line = QByteArray("42 (odd ) process) ") + fields.join(' ');
        const auto process = decodeProcessStat(line, 4096);
        QVERIFY(process.has_value());
        QCOMPARE(process->pid, 42);
        QCOMPARE(process->name, QStringLiteral("odd ) process"));
        QCOMPARE(process->ticks, 15ULL);
        QCOMPARE(process->startTime, 123456ULL);
        QCOMPARE(process->memoryBytes, 32768ULL);
        QVERIFY(!decodeProcessStat("42 (truncated) S 0", 4096));
        QVERIFY(!decodeProcessStat(line, -1));
        fields[21] = "-2";
        QVERIFY(!decodeProcessStat(QByteArray("42 (bad) ") + fields.join(' '), 4096));
    }
    void processSamplingAndSafety()
    {
        ProcessMonitor monitor;
        QVERIFY(!monitor.active());
        monitor.setActive(true);
        QVERIFY(monitor.processCount() > 0);
        QVERIFY(!monitor.endProcess(1, "0"));
        QVERIFY(!monitor.endProcess(QCoreApplication::applicationPid(), "0"));
        monitor.setQuery(QStringLiteral("no-such-nova-process-82be"));
        QVERIFY(monitor.processes().isEmpty());
        monitor.setQuery({});
        monitor.setSortBy(QStringLiteral("memory"));
        QVERIFY(!monitor.processes().isEmpty());
        QTRY_VERIFY_WITH_TIMEOUT(monitor.sampleCount() >= 2, 4000);
        monitor.setActive(false);
        const auto count = monitor.sampleCount();
        QTest::qWait(2100);
        QCOMPARE(monitor.sampleCount(), count);
        QTemporaryDir fixture;
        ProcessMonitor isolated(nullptr, fixture.path());
        isolated.setActive(true);
        QVERIFY(!isolated.message().isEmpty());
        QVERIFY(!isolated.endProcess(123, "12"));
    }
#ifdef Q_OS_LINUX
    void onlyTheConfirmedProcessIsSignalled()
    {
        QProcess child;
        child.start(QStringLiteral("/usr/bin/sleep"), {QStringLiteral("30")});
        QVERIFY(child.waitForStarted());
        const auto pid = child.processId();
        ProcessMonitor monitor;
        monitor.setActive(true);
        QString identity;
        for (const auto &row : monitor.processes()) if (row.toMap().value("pid").toInt() == pid) identity = row.toMap().value("startTime").toString();
        QVERIFY(!identity.isEmpty());
        QVERIFY(!monitor.endProcess(pid, "0"));
        QCOMPARE(child.state(), QProcess::Running);
        QVERIFY(monitor.endProcess(pid, identity));
        QVERIFY(child.waitForFinished(5000));
    }
#endif
    void workspaceRejectsUnknownTargets()
    {
        Workspace workspace;
        QVERIFY(!workspace.folders().isEmpty());
        QVERIFY(!workspace.openFolder(QStringLiteral("../../etc")));
        QVERIFY(!workspace.openVolume(QStringLiteral("/proc/sysrq-trigger")));
    }
};
QTEST_GUILESS_MAIN(DesktopTest)
#include "desktop_test.moc"
