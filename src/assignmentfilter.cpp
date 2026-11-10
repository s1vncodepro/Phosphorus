#include "assignmentfilter.h"

#include "assignmentstore.h"

AssignmentFilter::AssignmentFilter(AssignmentStore *store, QObject *parent)
    : QSortFilterProxyModel(parent), m_store(store)
{
    setSourceModel(store);
    setDynamicSortFilter(true);
    sort(0);

    connect(this, &QAbstractItemModel::rowsInserted, this, &AssignmentFilter::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &AssignmentFilter::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &AssignmentFilter::countChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &AssignmentFilter::countChanged);

    const auto bump = [this] { ++m_revision; emit revisionChanged(); };
    connect(this, &QAbstractItemModel::rowsInserted, this, bump);
    connect(this, &QAbstractItemModel::rowsRemoved, this, bump);
    connect(this, &QAbstractItemModel::modelReset, this, bump);
    connect(this, &QAbstractItemModel::layoutChanged, this, bump);
    connect(this, &QAbstractItemModel::dataChanged, this, bump);

    // A course filter that no longer matches anything (its last assignment was
    // deleted or renamed) would leave the list empty with no visible reason.
    connect(store, &AssignmentStore::statsChanged, this, [this] {
        if (!m_course.isEmpty() && !m_store->courses().contains(m_course, Qt::CaseInsensitive))
            setCourse(QString());
    });
}

int AssignmentFilter::sectionCount(const QString &status) const
{
    int count = 0;
    for (int row = 0; row < rowCount(); ++row) {
        if (index(row, 0).data(AssignmentStore::StatusRole).toString() == status)
            ++count;
    }
    return count;
}

void AssignmentFilter::setStatusFilter(const QString &value)
{
    if (m_statusFilter == value)
        return;
    m_statusFilter = value;
    invalidateFilter();
    emit statusFilterChanged();
}

void AssignmentFilter::setCourse(const QString &value)
{
    if (m_course == value)
        return;
    m_course = value;
    invalidateFilter();
    emit courseChanged();
}

void AssignmentFilter::setSearch(const QString &value)
{
    if (m_search == value)
        return;
    m_search = value;
    invalidateFilter();
    emit searchChanged();
}

void AssignmentFilter::setSortMode(const QString &value)
{
    if (m_sortMode == value)
        return;
    m_sortMode = value;
    invalidate();
    emit sortModeChanged();
}

bool AssignmentFilter::filterAcceptsRow(int sourceRow, const QModelIndex &) const
{
    const Assignment &a = m_store->at(sourceRow);
    const QString status = m_store->statusOf(a);

    if (m_statusFilter == QLatin1String("active") && a.done)
        return false;
    if (m_statusFilter == QLatin1String("done") && !a.done)
        return false;
    if (m_statusFilter == QLatin1String("overdue") && status != QLatin1String("overdue"))
        return false;
    if (m_statusFilter == QLatin1String("week") && status != QLatin1String("today")
        && status != QLatin1String("soon"))
        return false;

    if (!m_course.isEmpty() && a.course.compare(m_course, Qt::CaseInsensitive) != 0)
        return false;

    const QString needle = m_search.trimmed();
    if (!needle.isEmpty() && !a.title.contains(needle, Qt::CaseInsensitive)
        && !a.course.contains(needle, Qt::CaseInsensitive)
        && !a.notes.contains(needle, Qt::CaseInsensitive))
        return false;

    return true;
}

bool AssignmentFilter::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    const Assignment &a = m_store->at(left.row());
    const Assignment &b = m_store->at(right.row());

    // Finished work always sinks to the bottom.
    if (a.done != b.done)
        return !a.done;

    const auto byDue = [&]() -> int {
        if (a.due.isValid() != b.due.isValid())
            return a.due.isValid() ? -1 : 1;   // undated last
        if (a.due != b.due)
            return a.due < b.due ? -1 : 1;
        return 0;
    };
    const auto byPriority = [&]() -> int {
        return a.priority == b.priority ? 0 : (a.priority > b.priority ? -1 : 1);
    };
    const int byTitle = a.title.localeAwareCompare(b.title);

    int order = 0;
    if (m_sortMode == QLatin1String("title")) {
        order = byTitle != 0 ? byTitle : byDue();
    } else if (m_sortMode == QLatin1String("priority")) {
        order = byPriority();
        if (order == 0)
            order = byDue();
    } else {
        order = byDue();
        if (order == 0)
            order = byPriority();
    }
    if (order == 0)
        order = byTitle;
    return order < 0;
}
