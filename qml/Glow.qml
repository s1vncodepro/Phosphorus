import QtQuick

// A soft outer glow around the parent's border. Drawn as a few concentric
// outlines that fade out, so it needs no shader or blur module.
// Use as a child of a rounded Rectangle and pass that rectangle's radius.
Item {
    id: glow

    property color color: Theme.accent
    property real radius: 0
    property int spread: 7
    property real strength: 0.5   // 0 = off, 1 = full

    anchors.fill: parent
    z: -1

    Behavior on strength { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    Repeater {
        model: glow.spread

        Rectangle {
            required property int index
            readonly property real falloff: 1 - index / glow.spread

            anchors.fill: parent
            anchors.margins: -(index + 1)
            radius: glow.radius + index + 1
            color: "transparent"
            border.width: 2   // overlaps the next ring so corners have no gaps
            border.color: Theme.tint(glow.color, glow.strength * falloff * falloff * (Theme.dark ? 0.22 : 0.16))
        }
    }
}
