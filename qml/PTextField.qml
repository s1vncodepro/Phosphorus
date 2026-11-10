import QtQuick
import QtQuick.Controls

TextField {
    id: control

    property bool invalid: false

    implicitHeight: 40
    leftPadding: 12
    rightPadding: 12
    color: Theme.text
    placeholderTextColor: Theme.textFaint
    selectionColor: Theme.tint(Theme.primary, 0.3)
    selectedTextColor: Theme.text
    font.pixelSize: 14
    selectByMouse: true

    background: Rectangle {
        radius: 10
        color: Theme.surfaceAlt
        border.width: control.activeFocus || control.invalid ? 2 : 1
        border.color: control.invalid ? Theme.danger
                    : control.activeFocus ? Theme.primary : Theme.border

        Behavior on border.color { ColorAnimation { duration: Theme.fast } }

        Glow {
            color: control.invalid ? Theme.danger : Theme.primary
            radius: parent.radius
            strength: control.activeFocus ? 0.9 : 0
        }
    }
}
