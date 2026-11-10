import QtQuick
import QtQuick.Controls

// kind: "primary" (filled accent), "soft" (tinted), "ghost" (transparent)
AbstractButton {
    id: control

    property string kind: "ghost"
    property string iconName: ""
    property color tone: kind === "primary" ? Theme.onAccent : Theme.text
    property string tip: ""

    implicitHeight: 38
    implicitWidth: text.length > 0 ? row.implicitWidth + 28 : implicitHeight
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    scale: down ? 0.96 : 1

    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }

    Accessible.name: text.length > 0 ? text : tip

    ToolTip {
        id: tooltip
        visible: control.tip.length > 0 && control.hovered && !control.down
        delay: 600
        text: control.tip
        padding: 8
        contentItem: Text {
            text: tooltip.text
            color: Theme.text
            font.pixelSize: 12
        }
        background: Rectangle {
            radius: 8
            color: Theme.surfaceAlt
            border.width: 1
            border.color: Theme.border
        }
    }

    background: Rectangle {
        radius: 10
        color: {
            if (control.kind === "primary")
                return control.hovered ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
            if (control.kind === "soft")
                return Theme.tint(control.tone, control.hovered ? 0.2 : 0.12)
            return control.down ? Theme.border : control.hovered ? Theme.surfaceAlt : "transparent"
        }
        border.width: control.visualFocus ? 2 : 0
        border.color: control.kind === "primary" ? Theme.text : Theme.accent
        opacity: control.enabled ? 1 : 0.45

        Glow {
            visible: control.kind === "primary"
            radius: parent.radius
            strength: control.hovered ? 1 : 0.55
        }

        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    contentItem: Item {
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.iconName.length > 0
                name: control.iconName
                color: control.tone
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.text.length > 0
                text: control.text
                color: control.tone
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }
    }
}
