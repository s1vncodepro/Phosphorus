#pragma once

#include <QSortFilterProxyModel>

class AssignmentStore;

// The filtered, searched and sorted view of the store that the list shows.
class AssignmentFilter : public QSortFilterProxyModel
{
    Q_OBJECT
    // all | active | week | overdue | done
    Q_PROPERTY(QString statusFilter READ statusFilter WRITE setStatusFilter NOTIFY statusFilterChanged)
    Q_PROPERTY(QString course READ course WRITE setCourse NOTIFY courseChanged)
    Q_PROPERTY(QString search READ search WRITE setSearch NOTIFY searchChanged)
    // due | priority | title
    Q_PROPERTY(QString sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    // Bumps whenever the visible rows change in any way, so QML can re-run sectionCount().
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged)

public:
    explicit AssignmentFilter(AssignmentStore *store, QObject *parent = nullptr);

    QString statusFilter() const { return m_statusFilter; }
    void setStatusFilter(const QString &value);
    QString course() const { return m_course; }
    void setCourse(const QString &value);
    QString search() const { return m_search; }
    void setSearch(const QString &value);
    QString sortMode() const { return m_sortMode; }
    void setSortMode(const QString &value);
    int count() const { return rowCount(); }
    int revision() const { return m_revision; }

    // How many visible rows have this status (the list's section headings show it).
    Q_INVOKABLE int sectionCount(const QString &status) const;

signals:
    void statusFilterChanged();
    void courseChanged();
    void searchChanged();
    void sortModeChanged();
    void countChanged();
    void revisionChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

private:
    AssignmentStore *m_store;
    int m_revision = 0;
    QString m_statusFilter = QStringLiteral("all");
    QString m_course;
    QString m_search;
    QString m_sortMode = QStringLiteral("due");
};
