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
    required property int daysLeft
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
    border.color: hover.hovered ? Theme.tint(statusTone, 0.75) : Theme.tintOn(Theme.border, statusTone, 0.12)

    Glow {
        color: card.statusTone
        radius: card.radius
        strength: hover.hovered ? 1 : 0.15
    }

    // Soft drop shadow, drawn behind the card
    Rectangle {
        z: -2
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: -3
        radius: parent.radius
        color: Theme.shadow
    }

    // MouseAreas (not TapHandlers) so a click on the checkbox or a button is
    // consumed there and does not also open the editor.
    HoverHandler { id: hover }

    // Lifts on hover, on a spring
    transform: Translate {
        y: hover.hovered ? -2 : 0
        Behavior on y { SpringAnimation { spring: 5; damping: 0.28; epsilon: 0.05 } }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: card.editRequested(card.uid)
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 14
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

            // A ring that expands and fades when the box is ticked
            Rectangle {
                id: ripple
                anchors.centerIn: parent
                width: parent.width; height: width; radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
                opacity: 0
                ParallelAnimation {
                    id: rippleAnim
                    NumberAnimation { target: ripple; property: "scale"; from: 1; to: 2.6; duration: 520; easing.type: Easing.OutExpo }
                    NumberAnimation { target: ripple; property: "opacity"; from: 0.7; to: 0; duration: 520; easing.type: Easing.OutQuad }
                }
            }
            Connections {
                target: card
                function onDoneChanged() { if (card.done) rippleAnim.restart() }
            }

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
                Behavior on scale { NumberAnimation { duration: 520; easing.type: Easing.OutElastic; easing.amplitude: 1.3; easing.period: 0.45 } }
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
                    color: Theme.tint(Theme.text, 0.08)
                    Text {
                        id: courseText
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - 16)
                        text: card.course
                        elide: Text.ElideRight
                        color: Theme.text
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

                // Priority, as signal-style bars
                Row {
                    height: 24
                    spacing: 6
                    visible: !card.done
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 12
                        spacing: 2
                        Repeater {
                            model: 3
                            Rectangle {
                                required property int index
                                anchors.bottom: parent.bottom
                                width: 3; radius: 1
                                height: 5 + index * 3.5
                                color: index <= card.priority ? Theme.priorityColor(Math.max(card.priority, 1)) : Theme.border
                            }
                        }
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

        // Countdown
        Rectangle {
            // Hidden on narrow windows, where the due pill already says it.
            visible: !card.compact
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 4
            width: 68; height: 52; radius: 12
            color: Theme.tint(card.statusTone, 0.09)
            border.width: 1
            border.color: Theme.tint(card.statusTone, 0.28)

            Column {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: card.status === "done" ? "✓"
                        : card.status === "none" ? "–"
                        : card.status === "today" ? qsTr("Due")
                        : Math.abs(card.daysLeft)
                    color: card.statusTone
                    font.pixelSize: card.status === "today" ? 16 : 20
                    font.weight: Font.Bold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: card.status === "done" ? qsTr("done")
                        : card.status === "none" ? qsTr("no date")
                        : card.status === "today" ? qsTr("today")
                        : card.status === "overdue" ? (card.daysLeft === -1 ? qsTr("day late") : qsTr("days late"))
                        : (card.daysLeft === 1 ? qsTr("day left") : qsTr("days left"))
                    color: Theme.textMuted
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
