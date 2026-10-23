#include "DesktopActions.hpp"
#include "MetricsProvider.hpp"
#include "Preferences.hpp"
#include "SystemInfo.hpp"
#include "UpdateManager.hpp"
#include "ProfileManager.hpp"
#include "DriverCenter.hpp"
#include "Workspace.hpp"
#include "ProcessMonitor.hpp"
#include <KIconTheme>
#include <QGuiApplication>
#include <QFile>
#include <QJSEngine>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlError>
#include <QQuickItem>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTemporaryDir>
#include <QtTest>

class UiTest final : public QObject {
    Q_OBJECT
    bool focusByTab(QQuickWindow *window, const QString &name)
    {
        for (int attempt = 0; attempt < 80; ++attempt) {
            if (window->activeFocusItem() && window->activeFocusItem()->objectName() == name) return true;
            QTest::keyClick(window, Qt::Key_Tab);
            QTest::qWait(5);
        }
        qWarning() << "Keyboard focus did not reach" << name << "; current item:" << window->activeFocusItem();
        return false;
    }
private slots:
    void onlyBrandedPanelsAreMigrated()
    {
        QFile script(QFINDTESTDATA("../system/usr/share/plasma/shells/org.kde.plasma.desktop/contents/updates/nova-030.js"));
        QVERIFY(script.open(QIODevice::ReadOnly));
        const auto source = QString::fromUtf8(script.readAll());
        const auto setup = QString::fromLatin1(R"(
            var branded = true;
            var removed = false;
            var created = [];
            var old = {index: 2, globalShortcut: 'Alt+F1',
                readConfig: function() {return branded ? 'nova-control-center' : 'user-custom-icon';},
                remove: function() {removed = true;}};
            var panel = {alignment: 'left', lengthMode: 'fill', floating: false, height: 52,
                widgets: function() {return [old];},
                addWidget: function(name) {var widget = {type: name}; created.push(widget); return widget;}};
            var knownWidgetTypes = ['org.novaos.launcher'];
            function panels() {return [panel];}
        )");
        QJSEngine engine;
        QVERIFY(!engine.evaluate(setup).isError());
        const auto result = engine.evaluate(source);
        QVERIFY2(!result.isError(), qPrintable(result.toString()));
        QVERIFY(engine.globalObject().property("removed").toBool());
        const auto replacement = engine.globalObject().property("created").property(0);
        QCOMPARE(replacement.property("index").toInt(), 2);
        QCOMPARE(replacement.property("globalShortcut").toString(), QStringLiteral("Alt+F1"));
        QCOMPARE(engine.globalObject().property("old").property("globalShortcut").toString(), QString{});
        QCOMPARE(engine.globalObject().property("panel").property("alignment").toString(), QStringLiteral("center"));
        QJSEngine untouched;
        untouched.evaluate(setup);
        untouched.evaluate(QStringLiteral("branded = false"));
        QVERIFY(!untouched.evaluate(source).isError());
        QVERIFY(!untouched.globalObject().property("removed").toBool());
        QCOMPARE(untouched.globalObject().property("created").property("length").toInt(), 0);
        QCOMPARE(untouched.globalObject().property("panel").property("alignment").toString(), QStringLiteral("left"));
    }
    void keyboardNavigationAndPageLifecycle()
    {
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        Preferences preferences(nullptr, directory.filePath(QStringLiteral("novarc")), false);
        MetricsProvider metrics;
        SystemInfo info;
        DesktopActions actions;
        UpdateManager updates;
        ProfileManager profiles;
        DriverCenter drivers;
        Workspace workspace;
        ProcessMonitor processes;
        QQmlApplicationEngine engine;
        QStringList warnings;
        connect(&engine, &QQmlEngine::warnings, this, [&warnings](const QList<QQmlError> &errors) {
            for (const auto &error : errors) warnings.append(error.toString());
        });
        auto *context = engine.rootContext();
        context->setContextProperty(QStringLiteral("Preferences"), &preferences);
        context->setContextProperty(QStringLiteral("Metrics"), &metrics);
        context->setContextProperty(QStringLiteral("SystemInfo"), &info);
        context->setContextProperty(QStringLiteral("DesktopActions"), &actions);
        context->setContextProperty(QStringLiteral("Updates"), &updates);
        context->setContextProperty(QStringLiteral("Profiles"), &profiles);
        context->setContextProperty(QStringLiteral("Drivers"), &drivers);
        context->setContextProperty(QStringLiteral("Workspace"), &workspace);
        context->setContextProperty(QStringLiteral("Processes"), &processes);
        context->setContextProperty(QStringLiteral("welcomeMode"), false);
        context->setContextProperty(QStringLiteral("initialPage"), QVariant(0));
        context->setContextProperty(QStringLiteral("initialWidth"), 1280);
        context->setContextProperty(QStringLiteral("initialHeight"), 720);
        engine.load(QUrl(QStringLiteral("qrc:/ui/Main.qml")));
        QVERIFY2(!engine.rootObjects().isEmpty(), qPrintable(warnings.join('\n')));
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        QVERIFY(window);
        window->requestActivate();
        QTest::qWait(300);
        QVERIFY(!metrics.active());

        QVERIFY(focusByTab(window, QStringLiteral("nav-2")));
        QTest::keyClick(window, Qt::Key_Space);
        QTRY_COMPARE(window->property("page").toInt(), 2);
        QTRY_VERIFY(metrics.active());
        QTRY_VERIFY_WITH_TIMEOUT(metrics.sampleCount() >= 2, 10000);
        QVERIFY(metrics.memoryValid());

        QVERIFY(focusByTab(window, QStringLiteral("nav-1")));
        QTest::keyClick(window, Qt::Key_Space);
        QTRY_COMPARE(window->property("page").toInt(), 1);
        QTRY_VERIFY(!metrics.active());
        const auto samples = metrics.sampleCount();
        QTest::qWait(1200);
        QCOMPARE(metrics.sampleCount(), samples);

        QVERIFY(focusByTab(window, QStringLiteral("reduced-motion")));
        QTest::keyClick(window, Qt::Key_Space);
        QTRY_VERIFY(preferences.reducedMotion());
        QCOMPARE(preferences.panelDuration(), 0);

        QVERIFY(focusByTab(window, QStringLiteral("language-en")));
        QTest::keyClick(window, Qt::Key_Space);
        QTRY_COMPARE(preferences.language(), QStringLiteral("en"));
        QVERIFY(window->title().contains(QStringLiteral("Control Center")));
        window->setProperty("page", 4);
        QTest::qWait(100);
        window->setProperty("page", 5);
        QTest::qWait(100);
        window->setProperty("page", 6);
        QTest::qWait(100);
        QVERIFY(!processes.active());
        QVERIFY(!workspace.folders().isEmpty());
        window->setProperty("page", 7);
        QTest::qWait(2200);
        QVERIFY(processes.active());
        QVERIFY(processes.processCount() > 0);
        QVERIFY(processes.sampleCount() >= 2);
        window->setProperty("page", 0);
        QTest::qWait(100);
        QVERIFY(!processes.active());
        QVERIFY2(warnings.isEmpty(), qPrintable(warnings.join('\n')));
        window->close();
        QVERIFY(!metrics.active());
    }
};

int main(int argc, char **argv)
{
    KIconTheme::initTheme();
    QQuickStyle::setStyle(QStringLiteral("Basic"));
    QGuiApplication application(argc, argv);
    application.setApplicationName(QStringLiteral("nova-ui-test"));
    UiTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "ui_test.moc"
