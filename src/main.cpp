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
#include <QCommandLineParser>
#include <QGuiApplication>
#include <QFile>
#include <QIcon>
#include <QImage>
#include <QPainter>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QScreen>
#include <QSvgRenderer>
#include <QTimer>

int main(int argc, char **argv)
{
    KIconTheme::initTheme();
    QQuickStyle::setStyle(QStringLiteral("Basic"));
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("nova-control-center"));
    app.setApplicationDisplayName(QStringLiteral("NOVA Control Center"));
    app.setOrganizationName(QStringLiteral("NOVA"));
    app.setApplicationVersion(QStringLiteral("0.3.0-preview"));
    app.setDesktopFileName(QStringLiteral("org.novaos.ControlCenter"));
    app.setWindowIcon(QIcon(QStringLiteral(":/assets/nova-mark.svg")));
    QIcon::setFallbackThemeName(QStringLiteral("breeze"));
    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    parser.addOption({QStringLiteral("welcome"), QStringLiteral("Show first-run setup unless already completed")});
    parser.addOption({QStringLiteral("config"), QStringLiteral("Use an isolated preference file"), QStringLiteral("path")});
    parser.addOption({QStringLiteral("no-desktop-integration"), QStringLiteral("Do not change Plasma settings (for UI tests)")});
    parser.addOption({QStringLiteral("page"), QStringLiteral("Initial page: overview, appearance, performance, system, updates, drivers, thispc or tasks"), QStringLiteral("name"), QStringLiteral("overview")});
    parser.addOption({QStringLiteral("screenshot"), QStringLiteral("Capture the native window and exit"), QStringLiteral("path")});
    parser.addOption({QStringLiteral("render-wallpaper"), QStringLiteral("Render the bundled vector wallpaper to PNG and exit"), QStringLiteral("path")});
    parser.addOption({QStringLiteral("width"), QStringLiteral("Initial window width"), QStringLiteral("pixels"), QStringLiteral("1160")});
    parser.addOption({QStringLiteral("height"), QStringLiteral("Initial window height"), QStringLiteral("pixels"), QStringLiteral("760")});
    parser.process(app);
    if (parser.isSet(QStringLiteral("render-wallpaper"))) {
        QSvgRenderer renderer(QStringLiteral(":/assets/cosmic.svg"));
        if (!renderer.isValid()) return 2;
        QImage image(3840, 2160, QImage::Format_ARGB32_Premultiplied);
        image.fill(QColor(QStringLiteral("#0b0d14")));
        { QPainter painter(&image); renderer.render(&painter); }
        return image.save(parser.value(QStringLiteral("render-wallpaper"))) ? 0 : 2;
    }
    Preferences preferences(nullptr, parser.value(QStringLiteral("config")), !parser.isSet(QStringLiteral("no-desktop-integration")));
    if (parser.isSet(QStringLiteral("welcome"))) {
        QFile commandLine(QStringLiteral("/proc/cmdline"));
        bool minimal = false;
        if (commandLine.open(QIODevice::ReadOnly)) {
            const auto bootArguments = commandLine.readAll().simplified().split(' ');
            minimal = bootArguments.contains("rd.live.image") && bootArguments.contains("nova.minimal=1");
        }
        preferences.initializeSession(minimal);
    }
    if (parser.isSet(QStringLiteral("welcome")) && preferences.welcomeCompleted()) return 0;
    // Keep a pending desktop color operation alive if its window closes immediately.
    app.setQuitOnLastWindowClosed(false);
    auto quitWhenIdle = [&app, &preferences] {
        if (preferences.desktopBusy()) return;
        for (auto *window : app.topLevelWindows()) if (window->isVisible()) return;
        app.quit();
    };
    QObject::connect(&app, &QGuiApplication::lastWindowClosed, &app, quitWhenIdle);
    QObject::connect(&preferences, &Preferences::desktopBusyChanged, &app, quitWhenIdle);
    MetricsProvider metrics;
    SystemInfo info;
    DesktopActions actions;
    UpdateManager updates;
    ProfileManager profiles;
    DriverCenter drivers;
    Workspace workspace;
    ProcessMonitor processes;
    QQmlApplicationEngine engine;
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
    context->setContextProperty(QStringLiteral("welcomeMode"), parser.isSet(QStringLiteral("welcome")));
    const QStringList pages{QStringLiteral("overview"), QStringLiteral("appearance"), QStringLiteral("performance"), QStringLiteral("system"), QStringLiteral("updates"), QStringLiteral("drivers"), QStringLiteral("thispc"), QStringLiteral("tasks")};
    context->setContextProperty(QStringLiteral("initialPage"), qMax(0, pages.indexOf(parser.value(QStringLiteral("page")))));
    int initialWidth = qBound(800, parser.value(QStringLiteral("width")).toInt(), 3840);
    int initialHeight = qBound(600, parser.value(QStringLiteral("height")).toInt(), 2160);
    if (const auto *screen = QGuiApplication::primaryScreen()) {
        const auto available = screen->availableGeometry();
        // Leave room for decorations and panels, including panels omitted by a compositor.
        // Explicit dimensions remain exact for native captures and UI tests.
        if (!parser.isSet(QStringLiteral("width")))
            initialWidth = qMax(800, qMin(initialWidth, available.width() - 48));
        if (!parser.isSet(QStringLiteral("height")))
            initialHeight = qMax(600, qMin(initialHeight, available.height() - 80));
    }
    context->setContextProperty(QStringLiteral("initialWidth"), initialWidth);
    context->setContextProperty(QStringLiteral("initialHeight"), initialHeight);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/ui/Main.qml")));
    if (engine.rootObjects().isEmpty()) return 1;
    if (parser.isSet(QStringLiteral("screenshot"))) {
        const auto path = parser.value(QStringLiteral("screenshot"));
        QTimer::singleShot(3500, &app, [&app, &engine, path] {
            auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
            if (!window || !window->grabWindow().save(path)) app.exit(2);
            else app.exit(0);
        });
    }
    return app.exec();
}
