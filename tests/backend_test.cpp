#include "DesktopActions.hpp"
#include "MetricsProvider.hpp"
#include "Preferences.hpp"
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

class BackendTest final : public QObject {
    Q_OBJECT
private slots:
    void preferencePersistenceAndValidation()
    {
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        const auto path = directory.filePath(QStringLiteral("novarc"));
        {
            Preferences preferences(nullptr, path, false);
            QCOMPARE(preferences.motionProfile(), QStringLiteral("balanced"));
            preferences.setAccent(QStringLiteral("#9775FF"));
            preferences.setMotionProfile(QStringLiteral("cinematic"));
            preferences.setLanguage(QStringLiteral("en"));
            preferences.setReducedMotion(true);
            preferences.completeWelcome();
            QCOMPARE(preferences.panelDuration(), 0);
            preferences.setMotionProfile(QStringLiteral("invalid"));
            preferences.setAccent(QStringLiteral("red\n[KDE]\nInjected=true"));
            preferences.setLanguage(QStringLiteral("../../invalid"));
        }
        Preferences loaded(nullptr, path, false);
        QCOMPARE(loaded.accent(), QStringLiteral("#9775ff"));
        QCOMPARE(loaded.motionProfile(), QStringLiteral("cinematic"));
        QCOMPARE(loaded.language(), QStringLiteral("en"));
        QVERIFY(loaded.welcomeCompleted());
        QVERIFY(loaded.reducedMotion());
        QCOMPARE(loaded.windowDuration(), 0);
        loaded.setReducedMotion(false);
        QCOMPARE(loaded.windowDuration(), 180);
        loaded.setMotionProfile(QStringLiteral("minimal"));
        QCOMPARE(loaded.hoverDuration(), 0);
        QFile persisted(path);
        QVERIFY(persisted.open(QIODevice::ReadOnly));
        const auto contents = persisted.readAll();
        QVERIFY(contents.contains("WelcomeCompleted=true"));
        QVERIFY(!contents.contains("Injected"));
    }

    void samplingStopsWhenInactive()
    {
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        QFile stat(directory.filePath(QStringLiteral("stat")));
        QVERIFY(stat.open(QIODevice::WriteOnly));
        stat.write("cpu 100 0 20 500 0 0 0 0 0 0\n");
        stat.close();
        QFile memory(directory.filePath(QStringLiteral("meminfo")));
        QVERIFY(memory.open(QIODevice::WriteOnly));
        memory.write("MemTotal: 8388608 kB\nMemAvailable: 6291456 kB\n");
        memory.close();
        MetricsProvider metrics(nullptr, directory.path());
        QVERIFY(!metrics.active());
        QCOMPARE(metrics.sampleCount(), 0ULL);
        metrics.setActive(true);
        QVERIFY(metrics.memoryValid());
        QVERIFY(!metrics.cpuValid());
        QCOMPARE(metrics.memoryUsedGiB(), 2.0);
        QTRY_VERIFY_WITH_TIMEOUT(metrics.sampleCount() >= 2, 2500);
        metrics.setActive(false);
        const auto samples = metrics.sampleCount();
        QTest::qWait(1200);
        QCOMPARE(metrics.sampleCount(), samples);
        QVERIFY(!metrics.active());
    }

    void liveReducedEffectsOverridesCinematic()
    {
        QTemporaryDir directory;
        Preferences preferences(nullptr, directory.filePath(QStringLiteral("novarc")), false);
        preferences.setMotionProfile(QStringLiteral("cinematic"));
        preferences.initializeSession(true);
        QCOMPARE(preferences.motionProfile(), QStringLiteral("minimal"));
        QVERIFY(preferences.reducedMotion());
        QCOMPARE(preferences.panelDuration(), 0);
        QVERIFY(!preferences.welcomeCompleted());
    }

    void unavailableFilesStayUnavailable()
    {
        QTemporaryDir directory;
        MetricsProvider metrics(nullptr, directory.path());
        metrics.setActive(true);
        QVERIFY(!metrics.cpuValid());
        QVERIFY(!metrics.memoryValid());
        metrics.setActive(false);
    }

    void desktopActionsAreAnAllowlist()
    {
        DesktopActions actions;
        QVERIFY(!actions.launch(QStringLiteral("/bin/sh -c arbitrary")));
        QVERIFY(!actions.launch(QStringLiteral("settings; reboot")));
    }
};

QTEST_GUILESS_MAIN(BackendTest)
#include "backend_test.moc"
