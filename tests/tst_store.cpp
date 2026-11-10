#include "assignmentfilter.h"
#include "assignmentstore.h"

#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

class TestStore : public QObject
{
    Q_OBJECT

    static QStringList titles(const AssignmentFilter &filter)
    {
        QStringList result;
        for (int row = 0; row < filter.rowCount(); ++row)
            result << filter.index(row, 0).data(AssignmentStore::TitleRole).toString();
        return result;
    }

private slots:
    void addRejectsBlankTitle()
    {
        AssignmentStore store;
        QVERIFY(store.add("   ", "Math", "", 1, "").isEmpty());
        QCOMPARE(store.total(), 0);
    }

    void labelsAndCounts()
    {
        AssignmentStore store;
        store.setToday(QDate(2026, 11, 10));
        store.add("Late", "Math", "2026-11-07", 1, "");
        store.add("Yesterday", "Math", "2026-11-09", 1, "");
        const QString today = store.add("Today", "Art", "2026-11-10", 1, "");
        store.add("Tomorrow", "art", "2026-11-11", 1, "");
        store.add("Far", "", "2026-12-25", 1, "");
        store.add("Undated", "", "", 1, "");

        auto label = [&](int row) { return store.index(row).data(AssignmentStore::DueLabelRole).toString(); };
        QCOMPARE(label(0), QString("3 days overdue"));
        QCOMPARE(label(1), QString("1 day overdue"));
        QCOMPARE(label(2), QString("Due today"));
        QCOMPARE(label(3), QString("Due tomorrow"));
        QCOMPARE(label(4), QString("Due in 45 days"));
        QCOMPARE(label(5), QString("No due date"));

        QCOMPARE(store.overdueCount(), 2);
        QCOMPARE(store.weekCount(), 2);
        QCOMPARE(store.activeCount(), 6);
        QCOMPARE(store.courses(), QStringList({"Art", "Math"}));   // case-insensitive dedupe

        QVERIFY(store.setDone(today, true));
        QCOMPARE(store.doneCount(), 1);
        QCOMPARE(store.weekCount(), 1);
        QCOMPARE(label(2), QString("Completed"));

        // The day rolling over turns "tomorrow" into "today".
        store.setToday(QDate(2026, 11, 11));
        QCOMPARE(label(3), QString("Due today"));
    }

    void persistsAcrossRestarts()
    {
        QTemporaryDir dir;
        const QString path = dir.filePath("nested/assignments.json");
        QString id;
        {
            AssignmentStore store(path);
            id = store.add("Essay", "English", "2026-11-20", 2, "1500 words");
            store.add("Quiz", "", "", 0, "");
            store.setDone(id, true);
        }
        AssignmentStore reloaded(path);
        QCOMPARE(reloaded.total(), 2);
        const QVariantMap essay = reloaded.get(id);
        QCOMPARE(essay.value("title").toString(), QString("Essay"));
        QCOMPARE(essay.value("course").toString(), QString("English"));
        QCOMPARE(essay.value("due").toString(), QString("2026-11-20"));
        QCOMPARE(essay.value("priority").toInt(), 2);
        QCOMPARE(essay.value("notes").toString(), QString("1500 words"));
        QCOMPARE(essay.value("done").toBool(), true);
    }

    void corruptFileIsKeptNotOverwritten()
    {
        QTemporaryDir dir;
        const QString path = dir.filePath("assignments.json");
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("{ not json");
        file.close();

        QTest::ignoreMessage(QtWarningMsg, QRegularExpression("moved it aside"));
        AssignmentStore store(path);
        QCOMPARE(store.total(), 0);
        store.add("New", "", "", 1, "");
        QVERIFY(QFile::exists(path + ".corrupt"));
    }

    void updateRemoveUndo()
    {
        AssignmentStore store;
        const QString a = store.add("A", "", "", 1, "");
        const QString b = store.add("B", "", "", 1, "");
        store.add("C", "", "", 1, "");

        QVERIFY(store.update(b, "B2", "Bio", "2026-01-02", 9, "n"));
        QCOMPARE(store.get(b).value("title").toString(), QString("B2"));
        QCOMPARE(store.get(b).value("priority").toInt(), 2);   // clamped
        QVERIFY(!store.update(b, "", "", "", 1, ""));
        QVERIFY(!store.update("missing", "x", "", "", 1, ""));

        QVERIFY(!store.canUndoRemove());
        QVERIFY(store.remove(b));
        QCOMPARE(store.total(), 2);
        QVERIFY(store.canUndoRemove());
        QVERIFY(store.undoRemove());
        QCOMPARE(store.total(), 3);
        QCOMPARE(store.at(1).title, QString("B2"));   // back in its old slot
        QVERIFY(!store.undoRemove());

        store.setDone(a, true);
        QCOMPARE(store.clearCompleted(), 1);
        QCOMPARE(store.total(), 2);
    }

    void filterSearchAndSort()
    {
        AssignmentStore store;
        store.setToday(QDate(2026, 11, 10));
        AssignmentFilter filter(&store);

        store.add("Lab report", "Chemistry", "2026-11-12", 0, "titration");
        store.add("Problem set", "Math", "2026-11-08", 2, "");
        const QString essay = store.add("Essay", "English", "2026-11-30", 1, "");
        store.add("Reading", "English", "", 2, "");

        // Default: by due date, undated last.
        QCOMPARE(titles(filter), QStringList({"Problem set", "Lab report", "Essay", "Reading"}));

        filter.setSortMode("priority");
        QCOMPARE(titles(filter), QStringList({"Problem set", "Reading", "Essay", "Lab report"}));
        filter.setSortMode("title");
        QCOMPARE(titles(filter), QStringList({"Essay", "Lab report", "Problem set", "Reading"}));
        filter.setSortMode("due");

        filter.setStatusFilter("overdue");
        QCOMPARE(titles(filter), QStringList({"Problem set"}));
        filter.setStatusFilter("week");
        QCOMPARE(titles(filter), QStringList({"Lab report"}));

        // Completed work sinks to the bottom and leaves the "active" view.
        filter.setStatusFilter("all");
        store.setDone(store.at(1).id, true);
        QCOMPARE(titles(filter).last(), QString("Problem set"));
        filter.setStatusFilter("active");
        QCOMPARE(filter.count(), 3);
        filter.setStatusFilter("done");
        QCOMPARE(titles(filter), QStringList({"Problem set"}));
        filter.setStatusFilter("all");

        filter.setSearch("TITRA");   // matches notes, case-insensitively
        QCOMPARE(titles(filter), QStringList({"Lab report"}));
        filter.setSearch("");

        filter.setCourse("english");
        QCOMPARE(titles(filter), QStringList({"Essay", "Reading"}));

        // Deleting the last assignments of the selected course clears that filter.
        store.remove(essay);
        QCOMPARE(filter.course(), QString("english"));
        store.remove(store.at(2).id);
        QCOMPARE(filter.course(), QString());
        QCOMPARE(filter.count(), 2);
    }
};

QTEST_GUILESS_MAIN(TestStore)
#include "tst_store.moc"
