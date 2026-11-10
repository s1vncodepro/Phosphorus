import QtQuick

// A clickable summary tile; clicking it filters the list.
Rectangle {
    id: card

    property string label
    property int value: 0
    property color tone: Theme.accent
    property bool active: false
    signal clicked()

    // Counts up/down instead of snapping when the number changes.
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    implicitHeight: 84
    radius: Theme.radius
    color: active ? Theme.tint(tone, Theme.dark ? 0.14 : 0.1) : hover.containsMouse ? Theme.surfaceAlt : Theme.surface
    border.width: 1
    border.color: active ? Theme.tint(tone, 0.7) : Theme.border

    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

    Accessible.role: Accessible.Button
    Accessible.name: label + ": " + value

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        Row {
            spacing: 8
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 8; radius: 4
                color: card.tone
            }
            Text {
                text: card.label
                color: Theme.textMuted
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }
        Text {
            text: Math.round(card.shown)
            color: Theme.text
            font.pixelSize: 28
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }
}
