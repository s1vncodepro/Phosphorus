import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    // Below this width the sidebar folds away and the layout goes single-column.
    readonly property bool compact: width < 860

    readonly property var filterNames: ({
        "all": qsTr("All assignments"),
        "active": qsTr("To do"),
        "week": qsTr("Due this week"),
        "overdue": qsTr("Overdue"),
        "done": qsTr("Completed")
    })
    readonly property var sortNames: ({
        "due": qsTr("Due date"),
        "priority": qsTr("Priority"),
        "title": qsTr("Title")
    })
    readonly property bool filtering: assignments.statusFilter !== "all"
                                      || assignments.course.length > 0
                                      || assignments.search.length > 0

    function toggleFilter(key) {
        assignments.statusFilter = assignments.statusFilter === key ? "all" : key
    }

    function removeAssignment(uid) {
        const a = store.get(uid)
        if (store.remove(uid))
            toast.show(qsTr("Deleted “%1”").arg(a.title))
    }

    width: 1120
    height: 760
    minimumWidth: 380
    minimumHeight: 520
    visible: true
    title: "AssignmentReminder"
    color: Theme.bg

    Behavior on color { ColorAnimation { duration: Theme.normal } }

    Binding { target: Theme; property: "dark"; value: appSettings.darkMode }

    Shortcut { sequence: StandardKey.New; onActivated: editor.openNew() }
    Shortcut { sequence: StandardKey.Find; onActivated: searchField.forceActiveFocus() }

    EditorDialog {
        id: editor
        onRemoveRequested: uid => window.removeAssignment(uid)
    }

    // Soft accent wash behind the header (light theme only; matte black stays flat)
    Rectangle {
        width: parent.width
        height: 320
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.tintOn(Theme.bg, Theme.accent, Theme.dark ? 0 : 0.1) }
            GradientStop { position: 1; color: Theme.bg }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            Layout.fillHeight: true
            Layout.preferredWidth: 250
            visible: !window.compact
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: window.compact ? 16 : 28
            Layout.bottomMargin: 0
            spacing: 18

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: window.filterNames[assignments.statusFilter]
                        color: Theme.text
                        font.pixelSize: window.compact ? 22 : 26
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")
                              + "  ·  " + qsTr("%n to do", "", store.activeCount)
                        color: Theme.textMuted
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                }

                PButton {
                    iconName: Theme.dark ? "sun" : "moon"
                    tone: Theme.textMuted
                    tip: Theme.dark ? qsTr("Switch to light theme") : qsTr("Switch to dark theme")
                    onClicked: appSettings.darkMode = !appSettings.darkMode
                }
                PButton {
                    kind: "primary"
                    iconName: "plus"
                    text: window.compact ? "" : qsTr("New assignment")
                    tip: qsTr("New assignment")
                    onClicked: editor.openNew()
                }
            }

            // Summary tiles double as filters
            GridLayout {
                Layout.fillWidth: true
                columns: window.width < 620 ? 2 : 4
                columnSpacing: 14
                rowSpacing: 14

                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1   // equal-width columns
                    label: qsTr("To do"); iconName: "circle"; value: store.activeCount; tone: Theme.accent
                    detail: store.highCount > 0 ? qsTr("%1 high priority").arg(store.highCount) : qsTr("No high priority")
                    active: assignments.statusFilter === "active"
                    onClicked: window.toggleFilter("active")
                }
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1   // equal-width columns
                    label: qsTr("Due this week"); iconName: "clock"; value: store.weekCount; tone: Theme.info
                    detail: store.todayCount > 0 ? qsTr("%1 due today").arg(store.todayCount) : qsTr("Nothing due today")
                    active: assignments.statusFilter === "week"
                    onClicked: window.toggleFilter("week")
                }
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1   // equal-width columns
                    label: qsTr("Overdue"); iconName: "alert"; value: store.overdueCount; tone: Theme.danger
                    detail: store.overdueCount > 0 ? (store.oldestOverdueDays === 1 ? qsTr("Oldest: 1 day late") : qsTr("Oldest: %1 days late").arg(store.oldestOverdueDays)) : qsTr("All on time")
                    active: assignments.statusFilter === "overdue"
                    onClicked: window.toggleFilter("overdue")
                }
                StatCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1   // equal-width columns
                    label: qsTr("Completed"); iconName: "done"; value: store.doneCount; tone: Theme.textFaint
                    detail: store.total > 0 ? qsTr("%1% of everything").arg(Math.round(100 * store.doneCount / store.total)) : qsTr("Nothing added yet")
                    active: assignments.statusFilter === "done"
                    onClicked: window.toggleFilter("done")
                }
            }

            // The next seven days at a glance
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                radius: 16
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                Row {
                    anchors.fill: parent
                    anchors.margins: 8

                    Repeater {
                        model: store.weekDays

                        Item {
                            id: dayCell
                            required property var modelData
                            width: parent.width / 7
                            height: parent.height

                            Accessible.name: modelData.weekday + " " + modelData.day + ": " + qsTr("%n due", "", modelData.count)

                            Column {
                                anchors.centerIn: parent
                                spacing: 3

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: dayCell.modelData.today ? qsTr("TODAY") : dayCell.modelData.weekday.toUpperCase()
                                    color: dayCell.modelData.today ? Theme.text : Theme.textFaint
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.8
                                }
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 28; height: 28; radius: 14
                                    color: dayCell.modelData.today ? Theme.primary : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: dayCell.modelData.day
                                        color: dayCell.modelData.today ? Theme.onPrimary
                                             : dayCell.modelData.count > 0 ? Theme.text : Theme.textMuted
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                    }
                                }
                                // One dot per assignment due that day (up to four)
                                Item {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 30; height: 5   // keeps its slot when there are no dots
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        Repeater {
                                            model: Math.min(dayCell.modelData.count, 4)
                                            Rectangle {
                                                width: 5; height: 5; radius: 2.5
                                                color: dayCell.modelData.today ? Theme.warn : Theme.info
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Search + sort
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PTextField {
                    id: searchField
                    Layout.fillWidth: true
                    leftPadding: 38
                    rightPadding: 38
                    placeholderText: qsTr("Search assignments")
                    onTextChanged: assignments.search = text
                    Keys.onEscapePressed: { text = ""; focus = false }

                    Icon {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        name: "search"
                        color: Theme.textFaint
                    }
                    PButton {
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchField.text.length > 0
                        iconName: "close"
                        tone: Theme.textMuted
                        tip: qsTr("Clear search")
                        onClicked: searchField.text = ""
                    }
                }
                PButton {
                    iconName: "sort"
                    tone: Theme.textMuted
                    text: window.compact ? "" : window.sortNames[assignments.sortMode]
                    tip: qsTr("Sort by: %1 (click to change)").arg(window.sortNames[assignments.sortMode])
                    onClicked: {
                        const modes = ["due", "priority", "title"]
                        assignments.sortMode = modes[(modes.indexOf(assignments.sortMode) + 1) % modes.length]
                    }
                }
            }

            // Course chips
            ListView {
                id: courseBar
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.topMargin: -6
                visible: store.courses.length > 0
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: [""].concat(store.courses)

                delegate: Rectangle {
                    id: chip
                    required property string modelData
                    readonly property bool active: assignments.course.toLowerCase() === modelData.toLowerCase()

                    height: 32
                    width: chipLabel.implicitWidth + 26
                    radius: 16
                    color: active ? Theme.primary : chipHover.containsMouse ? Theme.surfaceAlt : Theme.surface
                    border.width: 1
                    border.color: active ? Theme.primary : Theme.border
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Accessible.role: Accessible.Button
                    Accessible.name: chipLabel.text

                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: chip.modelData.length > 0 ? chip.modelData : qsTr("All courses")
                        color: chip.active ? Theme.onPrimary : Theme.textMuted
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: chipHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: assignments.course = chip.modelData
                    }
                }
            }

            // The list
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: list
                    // Wider than its slot, with the cards inset to match, so the
                    // glow around each card is not clipped at the list's edges.
                    readonly property int bleed: 10
                    anchors.fill: parent
                    anchors.leftMargin: -bleed
                    anchors.rightMargin: -bleed
                    topMargin: 4
                    model: assignments
                    spacing: 10
                    clip: true
                    bottomMargin: 28
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { }

                    // Group by urgency while sorted by due date (the only order
                    // in which each group is one contiguous run).
                    section.property: assignments.sortMode === "due" ? "status" : ""
                    section.delegate: Item {
                        id: header
                        required property string section
                        width: list.width
                        height: 34

                        Row {
                            id: headerRow
                            anchors.left: parent.left
                            anchors.leftMargin: list.bleed + 4
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            spacing: 8

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8; height: 8; radius: 4
                                color: Theme.statusColor(header.section)
                            }
                            Text {
                                text: Theme.sectionName(header.section).toUpperCase()
                                color: Theme.textMuted
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                font.letterSpacing: 0.8
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: countText.implicitWidth + 12
                                height: 18; radius: 9
                                color: Theme.surfaceAlt
                                Text {
                                    id: countText
                                    anchors.centerIn: parent
                                    // Reading revision re-runs the count whenever the rows change.
                                    text: (assignments.revision, assignments.sectionCount(header.section))
                                    color: Theme.textMuted
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                            }
                        }
                        Rectangle {
                            anchors.left: headerRow.right
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: list.bleed + 2
                            anchors.verticalCenter: headerRow.verticalCenter
                            height: 1
                            color: Theme.border
                        }
                    }

                    delegate: AssignmentCard {
                        x: list.bleed
                        width: list.width - 2 * list.bleed
                        compact: window.compact
                        onEditRequested: uid => editor.openEdit(uid)
                        onRemoveRequested: uid => window.removeAssignment(uid)
                    }

                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal }
                            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.normal; easing.type: Easing.OutCubic }
                        }
                    }
                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; to: 0; duration: Theme.fast }
                            NumberAnimation { property: "scale"; to: 0.96; duration: Theme.fast }
                        }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: Theme.normal; easing.type: Easing.OutCubic }
                        // Finish any add animation this item was interrupted in.
                        NumberAnimation { property: "opacity"; to: 1; duration: Theme.fast }
                        NumberAnimation { property: "scale"; to: 1; duration: Theme.fast }
                    }
                    move: Transition {
                        NumberAnimation { properties: "x,y"; duration: Theme.normal; easing.type: Easing.OutCubic }
                    }
                }

                // Empty state
                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -20
                    width: Math.min(parent.width - 32, 360)
                    spacing: 10
                    visible: assignments.count === 0

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 56; height: 56; radius: 18
                        color: Theme.tint(Theme.accent, 0.14)
                        Icon {
                            anchors.centerIn: parent
                            name: window.filtering ? "search" : "check"
                            size: 26
                            color: Theme.accent
                        }
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: store.total === 0 ? qsTr("No assignments yet")
                            : window.filtering ? qsTr("Nothing matches") : qsTr("All clear")
                        color: Theme.text
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: store.total === 0
                              ? qsTr("Add your first assignment to start tracking what is due and when.")
                              : qsTr("No assignments fit the current filter or search.")
                        color: Theme.textMuted
                        font.pixelSize: 14
                    }
                    Item { width: 1; height: 4 }
                    PButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        kind: store.total === 0 ? "primary" : "soft"
                        tone: store.total === 0 ? Theme.onPrimary : Theme.primary
                        iconName: store.total === 0 ? "plus" : ""
                        text: store.total === 0 ? qsTr("Add assignment") : qsTr("Show everything")
                        onClicked: {
                            if (store.total === 0) {
                                editor.openNew()
                                return
                            }
                            searchField.text = ""
                            assignments.course = ""
                            assignments.statusFilter = "all"
                        }
                    }
                }
            }
        }
    }

    // "Deleted — Undo" toast
    Rectangle {
        id: toast

        property string message: ""
        property bool shown: false

        function show(text) {
            message = text
            shown = true
            toastTimer.restart()
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: shown ? 24 : -height
        width: Math.min(toastRow.implicitWidth + 28, parent.width - 24)
        height: 48
        radius: 12
        color: Theme.dark ? "#2A2F3A" : "#1D2129"
        opacity: shown ? 1 : 0
        z: 10

        Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }

        Timer { id: toastTimer; interval: 6000; onTriggered: toast.shown = false }

        RowLayout {
            id: toastRow
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 6
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: toast.message
                color: "#EDEFF3"
                font.pixelSize: 14
                elide: Text.ElideRight
            }
            PButton {
                visible: store.canUndoRemove
                iconName: "undo"
                text: qsTr("Undo")
                tone: "#3DDC97"
                onClicked: {
                    store.undoRemove()
                    toast.shown = false
                }
            }
        }
    }
}
