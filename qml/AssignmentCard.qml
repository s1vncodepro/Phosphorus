import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card

    required property string uid
    required property string title
    required property string course
    required property string notes
    required property string due
    required property string dueDate
    required property string dueLabel
    required property string status
    required property int priority
    required property bool done

    property bool compact: false
    signal editRequested(string uid)
    signal removeRequested(string uid)

    readonly property color statusTone: Theme.statusColor(status)

    implicitHeight: content.implicitHeight + 30
    radius: 16
    color: hover.hovered ? Theme.tintOn(Theme.surface, Theme.surfaceAlt, 0.6) : Theme.surface
    border.width: 1
    border.color: hover.hovered ? Theme.tint(statusTone, 0.5) : Theme.border

    // Soft drop shadow, drawn behind the card
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: -3
        radius: parent.radius
        color: Theme.shadow
    }

    // Status strip
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: parent.height - 28
        radius: 2
        color: card.statusTone
        opacity: card.done ? 0.45 : 1
        Behavior on color { ColorAnimation { duration: Theme.normal } }
    }

    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

    // MouseAreas (not TapHandlers) so a click on the checkbox or a button is
    // consumed there and does not also open the editor.
    HoverHandler { id: hover }
    MouseArea {
        anchors.fill: parent
        onClicked: card.editRequested(card.uid)
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 18
        anchors.rightMargin: 10
        spacing: 14

        // Round checkbox
        Rectangle {
            id: check
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 1
            width: 24; height: 24; radius: 12
            color: card.done ? Theme.accent : "transparent"
            border.width: 2
            border.color: card.done ? Theme.accent : checkTap.containsMouse ? Theme.accent : Theme.textFaint
            scale: checkTap.pressed ? 0.85 : 1

            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Behavior on border.color { ColorAnimation { duration: Theme.fast } }
            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }

            Accessible.role: Accessible.CheckBox
            Accessible.name: qsTr("Mark %1 as done").arg(card.title)
            Accessible.checked: card.done

            Icon {
                anchors.centerIn: parent
                name: "check"
                size: 15
                strokeWidth: 3
                color: Theme.onAccent
                opacity: card.done ? 1 : 0
                scale: card.done ? 1 : 0.4
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
            }

            MouseArea {
                id: checkTap
                anchors.fill: parent
                anchors.margins: -8   // larger hit target
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: store.setDone(card.uid, !card.done)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: card.title
                color: card.done ? Theme.textMuted : Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.strikeout: card.done
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: Theme.normal } }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                // Course pill
                Rectangle {
                    visible: card.course.length > 0
                    height: 24
                    width: Math.min(courseText.implicitWidth + 18, 200)
                    radius: 12
                    color: Theme.tint(Theme.accent, 0.13)
                    Text {
                        id: courseText
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - 16)
                        text: card.course
                        elide: Text.ElideRight
                        color: Theme.accent
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }

                // Due pill
                Rectangle {
                    height: 24
                    width: dueRow.implicitWidth + 18
                    radius: 12
                    color: Theme.tint(card.statusTone, 0.13)
                    Row {
                        id: dueRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: card.done ? "check" : "calendar"
                            size: 13
                            color: card.statusTone
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: card.dueLabel + (card.dueDate.length > 0 && !card.done ? "  ·  " + card.dueDate : "")
                            color: card.statusTone
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }
                }

                // Priority
                Row {
                    height: 24
                    spacing: 6
                    visible: !card.done
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7; height: 7; radius: 3.5
                        color: Theme.priorityColor(card.priority)
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Theme.priorityName(card.priority)
                        color: Theme.textMuted
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: card.notes.length > 0
                text: card.notes
                color: Theme.textMuted
                font.pixelSize: 13
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // Actions: revealed on hover with a mouse, always shown on narrow/touch layouts.
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            opacity: card.compact || hover.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }

            PButton {
                iconName: "edit"
                tone: Theme.textMuted
                tip: qsTr("Edit")
                onClicked: card.editRequested(card.uid)
            }
            PButton {
                iconName: "trash"
                tone: Theme.danger
                tip: qsTr("Delete")
                onClicked: card.removeRequested(card.uid)
            }
        }
    }
}
