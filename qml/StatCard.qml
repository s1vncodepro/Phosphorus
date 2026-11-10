import QtQuick

// A clickable summary tile; clicking it filters the list.
Item {
    id: card

    property string label
    property string iconName
    property string detail
    property int value: 0
    property color tone: Theme.accent
    property bool active: false
    signal clicked()

    // Counts up/down instead of snapping when the number changes.
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutExpo } }
    onValueChanged: pop.restart()

    implicitHeight: 112

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
                    : Theme.tintOn(Theme.border, card.tone, hover.containsMouse ? 0.6 : 0.12)

        Glow {
            color: card.tone
            radius: face.radius
            strength: card.active ? 1 : hover.containsMouse ? 0.7 : 0.2
        }
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.dark ? (card.active ? Theme.surfaceAlt : Theme.surface)
                                                     : card.active ? Theme.tintOn(Theme.surface, card.tone, 0.2) : Theme.surface }
            GradientStop { position: 1; color: Theme.dark ? (card.active || hover.containsMouse ? Theme.surfaceAlt : Theme.surface)
                                                     : Theme.tintOn(Theme.surface, card.tone, card.active ? 0.1 : hover.containsMouse ? 0.08 : 0.03) }
        }
        // Lifts on hover and sinks when pressed, on a spring
        transform: Translate {
            y: hover.pressed ? 1 : hover.containsMouse ? -3 : 0
            Behavior on y { SpringAnimation { spring: 5; damping: 0.28; epsilon: 0.05 } }
        }

        Behavior on border.color { ColorAnimation { duration: Theme.fast } }

        Text {
            x: 16; y: 14
            text: card.label
            color: Theme.textMuted
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        Text {
            x: 16; y: 34
            text: Math.round(card.shown)
            color: Theme.text
            font.pixelSize: 30
            font.weight: Font.Bold
        }
        Rectangle {
            x: 16
            anchors.bottom: detailText.top
            anchors.bottomMargin: 7
            width: parent.width - 32
            height: 1
            color: Theme.border
        }
        Text {
            id: detailText
            x: 16
            width: parent.width - 32
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            text: card.detail
            elide: Text.ElideRight
            color: Theme.textFaint
            font.pixelSize: 11
            font.weight: Font.Medium
        }
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            id: badge
            width: 34; height: 34; radius: 11
            color: Theme.tint(card.tone, card.active ? 0.28 : 0.15)
            rotation: card.active ? 360 : 0
            Behavior on rotation { NumberAnimation { duration: 650; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.overshoot } }

            // The badge jumps when its number changes
            SequentialAnimation {
                id: pop
                NumberAnimation { target: badge; property: "scale"; to: 1.3; duration: 110; easing.type: Easing.OutQuad }
                NumberAnimation {
                    target: badge; property: "scale"; to: 1; duration: 620
                    easing.type: Easing.OutElastic; easing.amplitude: 1.2; easing.period: 0.4
                }
            }
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
