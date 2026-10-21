#include "CompatController.hpp"
#include "CompatInspector.hpp"

#include <QCommandLineParser>
#include <QGuiApplication>
#include <QIcon>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStandardPaths>
#include <cstdio>

int main(int argc, char **argv)
{
    // Headless inspection is useful in a VM console and never launches the file.
    for (int index = 1; index < argc; ++index) {
        if (QString::fromLocal8Bit(argv[index]) == QStringLiteral("--inspect") && qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
            qputenv("QT_QPA_PLATFORM", "offscreen");
            break;
        }
    }
    QQuickStyle::setStyle(QStringLiteral("Basic"));
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("nova-compatibility"));
    app.setApplicationDisplayName(QStringLiteral("NOVA Smart Compatibility"));
    app.setDesktopFileName(QStringLiteral("nova-wine"));
    app.setWindowIcon(QIcon(QStringLiteral(":/assets/nova-mark.svg")));

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addOption({QStringLiteral("inspect"), QStringLiteral("Print an offline JSON assessment; never execute the file")});
    parser.addPositionalArgument(QStringLiteral("file"), QStringLiteral("Windows .exe file to inspect"));
    parser.process(app);
    if (parser.positionalArguments().size() != 1) {
        std::fputs("Usage: nova-compatibility [--inspect] FILE.exe\n", stderr);
        return 64;
    }
    const CompatReport report = inspectExecutable(parser.positionalArguments().first(),
                                                  !QStandardPaths::findExecutable(QStringLiteral("wine")).isEmpty());
    CompatController controller(report);
    if (parser.isSet(QStringLiteral("inspect"))) {
        const QJsonObject result{{QStringLiteral("fileName"), report.fileName},
                                 {QStringLiteral("validPe"), report.validPe},
                                 {QStringLiteral("architecture"), report.architecture},
                                 {QStringLiteral("wineInstalled"), report.wineInstalled},
                                 {QStringLiteral("canAttempt"), controller.canAttempt()},
                                 {QStringLiteral("productName"), report.productName},
                                 {QStringLiteral("nativeName"), report.nativeName},
                                 {QStringLiteral("nativeUrl"), report.nativeUrl},
                                 {QStringLiteral("problem"), report.problem}};
        std::fputs(QJsonDocument(result).toJson(QJsonDocument::Compact).constData(), stdout);
        std::fputc('\n', stdout);
        return report.validPe ? 0 : 2;
    }

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("Compatibility"), &controller);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/ui/Compatibility.qml")));
    return engine.rootObjects().isEmpty() ? 1 : app.exec();
}
