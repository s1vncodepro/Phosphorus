#include "appsettings.h"
#include "assignmentfilter.h"
#include "assignmentstore.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStandardPaths>

// The app used to be called Phosphorus and kept its data in a folder of that
// name. Copy it across once so a rename does not look like lost assignments.
static void carryOverOldData(const QString &dataDir)
{
    const QDir newDir(dataDir);
    if (newDir.exists(QStringLiteral("assignments.json")))
        return;
    const QDir oldDir(QFileInfo(dataDir).absolutePath() + QStringLiteral("/Phosphorus"));
    if (!oldDir.exists(QStringLiteral("assignments.json")))
        return;
    QDir().mkpath(dataDir);
    for (const char *name : {"assignments.json", "settings.ini"})
        QFile::copy(oldDir.filePath(QLatin1String(name)), newDir.filePath(QLatin1String(name)));
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("AssignmentReminder"));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("AssignmentReminder"));

    // The Basic style is the one meant to be restyled, and looks the same on every OS.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    // AR_DATA_DIR lets you keep the data somewhere else (e.g. a synced folder).
    QString dataDir = qEnvironmentVariable("AR_DATA_DIR");
    if (dataDir.isEmpty()) {
        dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        carryOverOldData(dataDir);
    }
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
    engine.load(QUrl(QStringLiteral("qrc:/AssignmentReminder/Main.qml")));

    return app.exec();
}
