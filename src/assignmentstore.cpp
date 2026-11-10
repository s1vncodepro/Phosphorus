#include "assignmentstore.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QSaveFile>
#include <QSet>
#include <QUuid>

#include <algorithm>

namespace {

QDate parseIso(const QString &iso)
{
    return iso.isEmpty() ? QDate() : QDate::fromString(iso, Qt::ISODate);
}

QString toIso(const QDate &date)
{
    return date.isValid() ? date.toString(Qt::ISODate) : QString();
}

} // namespace

AssignmentStore::AssignmentStore(const QString &filePath, QObject *parent)
    : QAbstractListModel(parent), m_filePath(filePath)
{
    load();

    // Relative labels ("Due tomorrow") go stale at midnight, so check once a
    // minute whether the day rolled over while the app was open.
    m_lastSeenDay = today();
    m_dayTimer.setInterval(60 * 1000);
    connect(&m_dayTimer, &QTimer::timeout, this, &AssignmentStore::refreshForNewDay);
    m_dayTimer.start();
}

int AssignmentStore::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

QHash<int, QByteArray> AssignmentStore::roleNames() const
{
    return {
        {UidRole, "uid"},
        {TitleRole, "title"},
        {CourseRole, "course"},
        {NotesRole, "notes"},
        {DueRole, "due"},
        {DueDateRole, "dueDate"},
        {DueLabelRole, "dueLabel"},
        {DaysLeftRole, "daysLeft"},
        {StatusRole, "status"},
        {PriorityRole, "priority"},
        {DoneRole, "done"},
    };
}

QVariant AssignmentStore::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const Assignment &a = m_items.at(index.row());
    const int daysLeft = a.due.isValid() ? int(today().daysTo(a.due)) : 0;

    switch (role) {
    case UidRole: return a.id;
    case Qt::DisplayRole:
    case TitleRole: return a.title;
    case CourseRole: return a.course;
    case NotesRole: return a.notes;
    case DueRole: return toIso(a.due);
    case DueDateRole: return formatDate(toIso(a.due));
    case DaysLeftRole: return daysLeft;
    case StatusRole: return statusOf(a);
    case PriorityRole: return a.priority;
    case DoneRole: return a.done;
    case DueLabelRole:
        if (a.done)
            return tr("Completed");
        if (!a.due.isValid())
            return tr("No due date");
        if (daysLeft < -1)
            return tr("%1 days overdue").arg(-daysLeft);
        if (daysLeft == -1)
            return tr("1 day overdue");
        if (daysLeft == 0)
            return tr("Due today");
        if (daysLeft == 1)
            return tr("Due tomorrow");
        return tr("Due in %1 days").arg(daysLeft);
    }
    return {};
}

QString AssignmentStore::statusOf(const Assignment &a) const
{
    if (a.done)
        return QStringLiteral("done");
    if (!a.due.isValid())
        return QStringLiteral("none");
    const qint64 daysLeft = today().daysTo(a.due);
    if (daysLeft < 0)
        return QStringLiteral("overdue");
    if (daysLeft == 0)
        return QStringLiteral("today");
    if (daysLeft <= 7)
        return QStringLiteral("soon");
    return QStringLiteral("later");
}

QString AssignmentStore::add(const QString &title, const QString &course, const QString &dueIso,
                             int priority, const QString &notes)
{
    const QString cleanTitle = title.trimmed();
    if (cleanTitle.isEmpty())
        return {};

    Assignment a;
    a.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    a.title = cleanTitle;
    a.course = course.trimmed();
    a.notes = notes.trimmed();
    a.due = parseIso(dueIso);
    a.priority = std::clamp(priority, 0, 2);

    beginInsertRows({}, m_items.size(), m_items.size());
    m_items.append(a);
    endInsertRows();
    changed();
    return a.id;
}

bool AssignmentStore::update(const QString &id, const QString &title, const QString &course,
                             const QString &dueIso, int priority, const QString &notes)
{
    const int row = indexOf(id);
    const QString cleanTitle = title.trimmed();
    if (row < 0 || cleanTitle.isEmpty())
        return false;

    Assignment &a = m_items[row];
    a.title = cleanTitle;
    a.course = course.trimmed();
    a.notes = notes.trimmed();
    a.due = parseIso(dueIso);
    a.priority = std::clamp(priority, 0, 2);

    emit dataChanged(index(row), index(row));
    changed();
    return true;
}

bool AssignmentStore::remove(const QString &id)
{
    const int row = indexOf(id);
    if (row < 0)
        return false;

    m_removed = m_items.at(row);
    m_removedRow = row;

    beginRemoveRows({}, row, row);
    m_items.removeAt(row);
    endRemoveRows();

    if (!m_hasRemoved) {
        m_hasRemoved = true;
        emit canUndoRemoveChanged();
    }
    changed();
    return true;
}

bool AssignmentStore::undoRemove()
{
    if (!m_hasRemoved)
        return false;

    const int row = std::clamp(m_removedRow, 0, int(m_items.size()));
    beginInsertRows({}, row, row);
    m_items.insert(row, m_removed);
    endInsertRows();

    m_hasRemoved = false;
    emit canUndoRemoveChanged();
    changed();
    return true;
}

bool AssignmentStore::setDone(const QString &id, bool done)
{
    const int row = indexOf(id);
    if (row < 0)
        return false;
    if (m_items[row].done == done)
        return true;

    m_items[row].done = done;
    emit dataChanged(index(row), index(row));
    changed();
    return true;
}

int AssignmentStore::clearCompleted()
{
    int removed = 0;
    for (int row = m_items.size() - 1; row >= 0; --row) {
        if (!m_items.at(row).done)
            continue;
        beginRemoveRows({}, row, row);
        m_items.removeAt(row);
        endRemoveRows();
        ++removed;
    }
    if (removed > 0)
        changed();
    return removed;
}

QVariantMap AssignmentStore::get(const QString &id) const
{
    const int row = indexOf(id);
    if (row < 0)
        return {};
    const Assignment &a = m_items.at(row);
    return {
        {"uid", a.id},
        {"title", a.title},
        {"course", a.course},
        {"notes", a.notes},
        {"due", toIso(a.due)},
        {"priority", a.priority},
        {"done", a.done},
    };
}

QString AssignmentStore::todayIso() const
{
    return toIso(today());
}

QString AssignmentStore::addDaysIso(int days) const
{
    return toIso(today().addDays(days));
}

QString AssignmentStore::formatDate(const QString &iso) const
{
    const QDate date = parseIso(iso);
    if (!date.isValid())
        return {};
    const QString format = date.year() == today().year() ? QStringLiteral("ddd, MMM d")
                                                         : QStringLiteral("ddd, MMM d, yyyy");
    return QLocale().toString(date, format);
}

int AssignmentStore::activeCount() const
{
    return total() - doneCount();
}

int AssignmentStore::doneCount() const
{
    return int(std::count_if(m_items.begin(), m_items.end(),
                             [](const Assignment &a) { return a.done; }));
}

int AssignmentStore::weekCount() const
{
    return int(std::count_if(m_items.begin(), m_items.end(), [this](const Assignment &a) {
        const QString status = statusOf(a);
        return status == QLatin1String("today") || status == QLatin1String("soon");
    }));
}

int AssignmentStore::overdueCount() const
{
    return int(std::count_if(m_items.begin(), m_items.end(), [this](const Assignment &a) {
        return statusOf(a) == QLatin1String("overdue");
    }));
}

QStringList AssignmentStore::courses() const
{
    QSet<QString> seen;
    QStringList result;
    for (const Assignment &a : m_items) {
        if (a.course.isEmpty() || seen.contains(a.course.toLower()))
            continue;
        seen.insert(a.course.toLower());
        result.append(a.course);
    }
    result.sort(Qt::CaseInsensitive);
    return result;
}

QDate AssignmentStore::today() const
{
    return m_todayOverride.isValid() ? m_todayOverride : QDate::currentDate();
}

void AssignmentStore::setToday(const QDate &date)
{
    m_todayOverride = date;
    m_lastSeenDay = QDate();
    refreshForNewDay();
}

void AssignmentStore::refreshForNewDay()
{
    if (m_lastSeenDay == today())
        return;
    m_lastSeenDay = today();
    if (!m_items.isEmpty())
        emit dataChanged(index(0), index(m_items.size() - 1));
    emit statsChanged();
}

int AssignmentStore::indexOf(const QString &id) const
{
    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items.at(i).id == id)
            return i;
    }
    return -1;
}

void AssignmentStore::changed()
{
    save();
    emit statsChanged();
}

void AssignmentStore::load()
{
    if (m_filePath.isEmpty())
        return;
    QFile file(m_filePath);
    if (!file.open(QIODevice::ReadOnly))
        return;

    QJsonParseError error{};
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &error);
    file.close();
    if (error.error != QJsonParseError::NoError || !doc.isObject()) {
        // Keep the unreadable file around instead of overwriting it on the next save.
        QFile::remove(m_filePath + QStringLiteral(".corrupt"));
        QFile::rename(m_filePath, m_filePath + QStringLiteral(".corrupt"));
        qWarning("Could not read %s (%s); moved it aside as .corrupt",
                 qPrintable(m_filePath), qPrintable(error.errorString()));
        return;
    }

    const QJsonArray array = doc.object().value(QLatin1String("assignments")).toArray();
    for (const QJsonValue &value : array) {
        const QJsonObject o = value.toObject();
        Assignment a;
        a.id = o.value(QLatin1String("id")).toString();
        a.title = o.value(QLatin1String("title")).toString();
        a.course = o.value(QLatin1String("course")).toString();
        a.notes = o.value(QLatin1String("notes")).toString();
        a.due = parseIso(o.value(QLatin1String("due")).toString());
        a.priority = std::clamp(o.value(QLatin1String("priority")).toInt(1), 0, 2);
        a.done = o.value(QLatin1String("done")).toBool();
        if (a.id.isEmpty())
            a.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
        if (!a.title.isEmpty())
            m_items.append(a);
    }
}

void AssignmentStore::save() const
{
    if (m_filePath.isEmpty())
        return;

    QJsonArray array;
    for (const Assignment &a : m_items) {
        array.append(QJsonObject{
            {"id", a.id},
            {"title", a.title},
            {"course", a.course},
            {"notes", a.notes},
            {"due", toIso(a.due)},
            {"priority", a.priority},
            {"done", a.done},
        });
    }
    const QJsonObject root{{"version", 1}, {"assignments", array}};

    QDir().mkpath(QFileInfo(m_filePath).absolutePath());
    QSaveFile file(m_filePath);   // atomic: a crash mid-write cannot truncate the data
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning("Could not save to %s", qPrintable(m_filePath));
        return;
    }
    file.write(QJsonDocument(root).toJson());
    if (!file.commit())
        qWarning("Could not save to %s", qPrintable(m_filePath));
}
