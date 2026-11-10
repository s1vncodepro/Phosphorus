import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sidebar

    color: Theme.surface
    Behavior on color { ColorAnimation { duration: Theme.normal } }

    readonly property var filters: [
        { key: "all", label: qsTr("All assignments"), count: store.total, tone: Theme.textMuted },
        { key: "active", label: qsTr("To do"), count: store.activeCount, tone: Theme.accent },
        { key: "week", label: qsTr("Due this week"), count: store.weekCount, tone: Theme.info },
        { key: "overdue", label: qsTr("Overdue"), count: store.overdueCount, tone: Theme.danger },
        { key: "done", label: qsTr("Completed"), count: store.doneCount, tone: Theme.textFaint }
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
                width: 30; height: 30; radius: 9
                color: Theme.accent
                Icon { anchors.centerIn: parent; name: "check"; color: Theme.onAccent; strokeWidth: 2.6 }
            }
            Text {
                text: "Phosphorus"
                color: Theme.text
                font.pixelSize: 18
                font.weight: Font.Bold
            }
        }

        Repeater {
            model: sidebar.filters

            Rectangle {
                id: item
                required property var modelData
                readonly property bool active: assignments.statusFilter === modelData.key

                Layout.fillWidth: true
                height: 40
                radius: 10
                color: active ? Theme.tint(Theme.accent, 0.14) : hover.containsMouse ? Theme.surfaceAlt : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                Accessible.role: Accessible.Button
                Accessible.name: modelData.label

                Rectangle {
                    id: dot
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8; height: 8; radius: 4
                    color: item.modelData.tone
                }
                Text {
                    anchors.left: dot.right
                    anchors.leftMargin: 12
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
                    color: item.active ? Theme.accent : Theme.textFaint
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

        Item { Layout.fillHeight: true }

        // Overall progress
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: progressColumn.implicitHeight + 28
            radius: Theme.radius
            color: Theme.surfaceAlt
            visible: store.total > 0

            readonly property real fraction: store.total > 0 ? store.doneCount / store.total : 0

            Column {
                id: progressColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                Text {
                    text: qsTr("Progress")
                    color: Theme.textMuted
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Text {
                    text: qsTr("%1 of %2 done").arg(store.doneCount).arg(store.total)
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    width: parent.width
                    height: 6; radius: 3
                    color: Theme.border

                    Rectangle {
                        height: parent.height; radius: 3
                        color: Theme.accent
                        width: parent.width * parent.parent.parent.fraction
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}
