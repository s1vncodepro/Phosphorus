#pragma once

#include <QObject>
#include <QSettings>

// The handful of UI preferences that should survive a restart.
class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged)

public:
    explicit AppSettings(const QString &filePath, QObject *parent = nullptr)
        : QObject(parent), m_settings(filePath, QSettings::IniFormat)
    {
    }

    bool darkMode() const { return m_settings.value("darkMode", true).toBool(); }
    void setDarkMode(bool value)
    {
        if (value == darkMode())
            return;
        m_settings.setValue("darkMode", value);
        emit darkModeChanged();
    }

signals:
    void darkModeChanged();

private:
    QSettings m_settings;
};
