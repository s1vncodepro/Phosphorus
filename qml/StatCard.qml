import QtQuick

// A clickable summary tile; clicking it filters the list.
Item {
    id: card

    property string label
    property string iconName
    property int value: 0
    property color tone: Theme.accent
    property bool active: false
    signal clicked()

    // Counts up/down instead of snapping when the number changes.
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    implicitHeight: 92

    Accessible.role: Accessible.Button
    Accessible.name: label + ": " + value

    // Soft drop shadow
    Rectangle {
        anchors.fill: face
        anchors.topMargin: hover.containsMouse ? 5 : 3
        anchors.bottomMargin: hover.containsMouse ? -5 : -3
        radius: face.radius
        color: Theme.shadow
        Behavior on anchors.topMargin { NumberAnimation { duration: Theme.fast } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.fast } }
    }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: 16
        border.width: 1
        border.color: card.active ? Theme.tint(card.tone, 0.85)
                    : Theme.tintOn(Theme.border, card.tone, hover.containsMouse ? 0.7 : 0.3)

        Glow {
            color: card.tone
            radius: face.radius
            strength: card.active ? 1 : hover.containsMouse ? 0.8 : 0.4
        }
        gradient: Gradient {
            GradientStop { position: 0; color: card.active ? Theme.tintOn(Theme.surface, card.tone, 0.2) : Theme.surface }
            GradientStop { position: 1; color: Theme.tintOn(Theme.surface, card.tone, card.active ? 0.1 : hover.containsMouse ? 0.08 : 0.03) }
        }
        transform: Translate { y: hover.containsMouse ? -1 : 0 }

        Behavior on border.color { ColorAnimation { duration: Theme.fast } }

        Text {
            x: 16; y: 14
            text: card.label
            color: Theme.textMuted
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            x: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            text: Math.round(card.shown)
            color: Theme.text
            font.pixelSize: 30
            font.weight: Font.Bold
        }
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            width: 34; height: 34; radius: 11
            color: Theme.tint(card.tone, card.active ? 0.28 : 0.15)
            Icon { anchors.centerIn: parent; name: card.iconName; color: card.tone }
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
