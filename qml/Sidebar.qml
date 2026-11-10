import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sidebar

    color: Theme.dark ? Theme.bg : Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.normal } }

    readonly property var filters: [
        { key: "all", icon: "list", label: qsTr("All assignments"), count: store.total, tone: Theme.textMuted },
        { key: "active", icon: "circle", label: qsTr("To do"), count: store.activeCount, tone: Theme.accent },
        { key: "week", icon: "clock", label: qsTr("Due this week"), count: store.weekCount, tone: Theme.info },
        { key: "overdue", icon: "alert", label: qsTr("Overdue"), count: store.overdueCount, tone: Theme.danger },
        { key: "done", icon: "done", label: qsTr("Completed"), count: store.doneCount, tone: Theme.textFaint }
    ]

    Rectangle {
        anchors.right: parent.right
        width: 1; height: parent.height
        color: Theme.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 4

        RowLayout {
            Layout.bottomMargin: 18
            Layout.topMargin: 6
            Layout.leftMargin: 6
            spacing: 10

            Rectangle {
                width: 34; height: 34; radius: 10
                color: Theme.primary
                Text {
                    anchors.centerIn: parent
                    text: "AR"
                    color: Theme.onPrimary
                    font.pixelSize: 14
                    font.weight: Font.Black
                    font.letterSpacing: 0.5
                }
            }
            Column {
                spacing: 1
                Text {
                    text: "AssignmentReminder"
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }
                Text {
                    text: (store.total === 1 ? qsTr("1 assignment") : qsTr("%1 assignments").arg(store.total))
                    color: Theme.textFaint
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }

        Item {
            id: nav
            Layout.fillWidth: true
            implicitHeight: sidebar.filters.length * 46 - 4

            readonly property int activeIndex: {
                for (let i = 0; i < sidebar.filters.length; ++i) {
                    if (sidebar.filters[i].key === assignments.statusFilter)
                        return i
                }
                return 0
            }

            // One highlight that springs from item to item instead of each row
            // switching its own background on and off.
            Rectangle {
                width: parent.width
                height: 42
                radius: 12
                color: Theme.tint(Theme.primary, Theme.dark ? 0.09 : 0.14)
                y: nav.activeIndex * 46
                Behavior on y { SpringAnimation { spring: 4.5; damping: 0.36; epsilon: 0.1 } }
            }

            Column {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: sidebar.filters

                    Rectangle {
                        id: item
                        required property var modelData
                        readonly property bool active: assignments.statusFilter === modelData.key

                        width: parent.width
                        height: 42
                        radius: 12
                        color: !active && hover.containsMouse ? Theme.surfaceAlt : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }

                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.label

                        Icon {
                            id: dot
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            size: 17
                            name: item.modelData.icon
                            color: item.active ? Theme.text : item.modelData.tone
                        }
                        Text {
                            anchors.left: dot.right
                            anchors.leftMargin: 11
                            anchors.right: count.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: item.modelData.label
                            elide: Text.ElideRight
                            color: item.active ? Theme.text : Theme.textMuted
                            font.pixelSize: 14
                            font.weight: item.active ? Font.DemiBold : Font.Medium
                        }
                        Text {
                            id: count
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: item.modelData.count
                            color: item.active ? Theme.text : Theme.textFaint
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: assignments.statusFilter = item.modelData.key
                        }
                    }
                }
            }
        }

        // Per-course breakdown
        Text {
            Layout.topMargin: 18
            Layout.leftMargin: 12
            Layout.bottomMargin: 4
            visible: store.courseStats.length > 0
            text: qsTr("COURSES")
            color: Theme.textFaint
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 1
        }
        Repeater {
            model: store.courseStats.slice(0, 6)

            Rectangle {
                id: courseRow
                required property var modelData
                readonly property bool active: assignments.course.toLowerCase() === modelData.name.toLowerCase()

                Layout.fillWidth: true
                height: 44
                radius: 12
                color: active ? Theme.tint(Theme.primary, Theme.dark ? 0.09 : 0.14)
                     : courseHover.containsMouse ? Theme.surfaceAlt : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                Accessible.role: Accessible.Button
                Accessible.name: modelData.name

                Text {
                    id: courseName
                    x: 12; y: 8
                    width: parent.width - 24 - courseCount.width - 8
                    text: courseRow.modelData.name
                    elide: Text.ElideRight
                    color: courseRow.active ? Theme.text : Theme.textMuted
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
                Text {
                    id: courseCount
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    y: 9
                    text: courseRow.modelData.done + "/" + courseRow.modelData.total
                    color: Theme.textFaint
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    x: 12
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    width: parent.width - 24
                    height: 3; radius: 1.5
                    color: Theme.border

                    Rectangle {
                        height: parent.height; radius: 1.5
                        color: Theme.accent
                        width: parent.width * courseRow.modelData.done / Math.max(1, courseRow.modelData.total)
                        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutExpo } }
                    }
                }
                MouseArea {
                    id: courseHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: assignments.course = courseRow.active ? "" : courseRow.modelData.name
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Overall progress
        Rectangle {
            id: progress
            Layout.fillWidth: true
            implicitHeight: 84
            radius: 16
            color: Theme.surfaceAlt
            visible: store.total > 0

            property real fraction: store.total > 0 ? store.doneCount / store.total : 0
            // A loose spring, so the ring swings past the new value and settles
            Behavior on fraction { SpringAnimation { spring: 2.2; damping: 0.22; epsilon: 0.001 } }
            onFractionChanged: ring.requestPaint()

            Canvas {
                id: ring
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 56; height: 56
                antialiasing: true

                property color track: Theme.border
                property color fill: Theme.accent
                onTrackChanged: requestPaint()
                onFillChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.lineWidth = 6
                    ctx.lineCap = "round"
                    ctx.strokeStyle = track
                    ctx.beginPath()
                    ctx.arc(28, 28, 23, 0, 2 * Math.PI)
                    ctx.stroke()
                    if (progress.fraction > 0.001) {
                        ctx.strokeStyle = fill
                        ctx.beginPath()
                        ctx.arc(28, 28, 23, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.min(1, progress.fraction))
                        ctx.stroke()
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: Math.round(Math.max(0, Math.min(1, progress.fraction)) * 100) + "%"
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }

            Column {
                anchors.left: ring.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: qsTr("Progress")
                    color: Theme.textMuted
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    text: qsTr("%1 of %2 done").arg(store.doneCount).arg(store.total)
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }
    }
}
