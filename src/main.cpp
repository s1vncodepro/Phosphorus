#include "appsettings.h"
#include "assignmentfilter.h"
#include "assignmentstore.h"

#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStandardPaths>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("Phosphorus"));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("Phosphorus"));

    // The Basic style is the one meant to be restyled, and looks the same on every OS.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    // PHOSPHORUS_DATA_DIR lets you keep the data somewhere else (e.g. a synced folder).
    QString dataDir = qEnvironmentVariable("PHOSPHORUS_DATA_DIR");
    if (dataDir.isEmpty())
        dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);

    AssignmentStore store(QDir(dataDir).filePath(QStringLiteral("assignments.json")));
    AssignmentFilter filter(&store);
    AppSettings settings(QDir(dataDir).filePath(QStringLiteral("settings.ini")));

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("store"), &store);
    engine.rootContext()->setContextProperty(QStringLiteral("assignments"), &filter);
    engine.rootContext()->setContextProperty(QStringLiteral("appSettings"), &settings);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/Phosphorus/Main.qml")));

    return app.exec();
}
