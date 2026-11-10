#pragma once

#include <QAbstractListModel>
#include <QDate>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

struct Assignment {
    QString id;
    QString title;
    QString course;
    QString notes;
    QDate due;          // invalid = no due date
    int priority = 1;   // 0 low, 1 medium, 2 high
    bool done = false;
};

// Owns the user's assignments, exposes them to QML as a list model and
// saves them to a JSON file after every change.
class AssignmentStore : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int total READ total NOTIFY statsChanged)
    Q_PROPERTY(int activeCount READ activeCount NOTIFY statsChanged)
    Q_PROPERTY(int weekCount READ weekCount NOTIFY statsChanged)
    Q_PROPERTY(int overdueCount READ overdueCount NOTIFY statsChanged)
    Q_PROPERTY(int doneCount READ doneCount NOTIFY statsChanged)
    Q_PROPERTY(int highCount READ highCount NOTIFY statsChanged)
    Q_PROPERTY(int todayCount READ todayCount NOTIFY statsChanged)
    Q_PROPERTY(int oldestOverdueDays READ oldestOverdueDays NOTIFY statsChanged)
    Q_PROPERTY(QStringList courses READ courses NOTIFY statsChanged)
    Q_PROPERTY(QVariantList courseStats READ courseStats NOTIFY statsChanged)
    Q_PROPERTY(QVariantList weekDays READ weekDays NOTIFY statsChanged)
    Q_PROPERTY(bool canUndoRemove READ canUndoRemove NOTIFY canUndoRemoveChanged)

public:
    enum Roles {
        UidRole = Qt::UserRole + 1,
        TitleRole,
        CourseRole,
        NotesRole,
        DueRole,        // ISO date string, empty when there is no due date
        DueDateRole,    // human readable date, e.g. "Thu, Nov 12"
        DueLabelRole,   // relative label, e.g. "Due in 3 days"
        DaysLeftRole,
        StatusRole,     // done | none | overdue | today | soon | later
        PriorityRole,
        DoneRole,
    };

    // An empty path keeps everything in memory (used by the tests).
    explicit AssignmentStore(const QString &filePath = QString(), QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Dates cross the QML boundary as ISO strings (yyyy-MM-dd) to avoid
    // JavaScript Date timezone surprises.
    Q_INVOKABLE QString add(const QString &title, const QString &course, const QString &dueIso,
                            int priority, const QString &notes);
    Q_INVOKABLE bool update(const QString &id, const QString &title, const QString &course,
                            const QString &dueIso, int priority, const QString &notes);
    Q_INVOKABLE bool remove(const QString &id);
    Q_INVOKABLE bool undoRemove();
    Q_INVOKABLE bool setDone(const QString &id, bool done);
    Q_INVOKABLE int clearCompleted();
    Q_INVOKABLE QVariantMap get(const QString &id) const;

    Q_INVOKABLE QString todayIso() const;
    Q_INVOKABLE QString addDaysIso(int days) const;
    Q_INVOKABLE QString formatDate(const QString &iso) const;

    int total() const { return m_items.size(); }
    int activeCount() const;
    int weekCount() const;
    int overdueCount() const;
    int doneCount() const;
    int highCount() const;           // unfinished, high priority
    int todayCount() const;          // unfinished, due today
    int oldestOverdueDays() const;   // 0 when nothing is overdue
    QStringList courses() const;
    QVariantList courseStats() const;   // [{name, total, done}]
    QVariantList weekDays() const;      // today + 6 days: [{iso, weekday, day, count, today}]
    bool canUndoRemove() const { return m_hasRemoved; }

    const Assignment &at(int row) const { return m_items.at(row); }
    QString statusOf(const Assignment &a) const;
    QDate today() const;
    void setToday(const QDate &date);   // test hook; an invalid date means "use the clock"

signals:
    void statsChanged();
    void canUndoRemoveChanged();

private:
    int indexOf(const QString &id) const;
    void load();
    void save() const;
    void changed();
    void refreshForNewDay();

    QString m_filePath;
    QVector<Assignment> m_items;
    Assignment m_removed;
    int m_removedRow = 0;
    bool m_hasRemoved = false;
    QDate m_todayOverride;
    QDate m_lastSeenDay;
    QTimer m_dayTimer;
};
