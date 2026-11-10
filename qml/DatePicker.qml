import QtQuick
import QtQuick.Controls

// Inline month calendar. Works in ISO date strings (yyyy-MM-dd).
Column {
    id: picker

    property string value: ""
    property string today: ""
    property int year: new Date().getFullYear()
    property int month: new Date().getMonth()   // 0-based, like JavaScript
    signal picked(string iso)

    spacing: 6

    function iso(y, m, d) {
        return y + "-" + String(m + 1).padStart(2, "0") + "-" + String(d).padStart(2, "0")
    }

    // Jump to the month of the selected date (or the current month).
    function reveal() {
        const source = value.length > 0 ? value : today
        if (source.length === 0)
            return
        year = parseInt(source.substring(0, 4))
        month = parseInt(source.substring(5, 7)) - 1
    }

    function step(delta) {
        const next = month + delta
        year += Math.floor(next / 12)
        month = ((next % 12) + 12) % 12
    }

    Item {
        width: parent.width
        height: 36

        PButton { anchors.left: parent.left; iconName: "left"; tip: qsTr("Previous month"); onClicked: picker.step(-1) }
        Text {
            anchors.centerIn: parent
            text: Qt.locale().standaloneMonthName(picker.month) + " " + picker.year
            color: Theme.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        PButton { anchors.right: parent.right; iconName: "right"; tip: qsTr("Next month"); onClicked: picker.step(1) }
    }

    DayOfWeekRow {
        width: parent.width
        locale: grid.locale
        delegate: Text {
            required property string shortName
            text: shortName
            color: Theme.textFaint
            font.pixelSize: 12
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MonthGrid {
        id: grid
        width: parent.width
        height: 6 * 36
        year: picker.year
        month: picker.month
        locale: Qt.locale()

        delegate: Item {
            id: cell
            required property var model
            readonly property string iso: picker.iso(model.year, model.month, model.day)
            readonly property bool selected: iso === picker.value
            readonly property bool inMonth: model.month === grid.month

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) - 4
                height: width
                radius: width / 2
                color: cell.selected ? Theme.accent : cellHover.containsMouse ? Theme.border : "transparent"
                border.width: cell.iso === picker.today && !cell.selected ? 1.5 : 0
                border.color: Theme.accent
                Behavior on color { ColorAnimation { duration: 90 } }

                Text {
                    anchors.centerIn: parent
                    text: cell.model.day
                    color: cell.selected ? Theme.onAccent : Theme.text
                    opacity: cell.inMonth || cell.selected ? 1 : 0.3
                    font.pixelSize: 13
                    font.weight: cell.selected || cell.iso === picker.today ? Font.Bold : Font.Normal
                }
            }

            MouseArea {
                id: cellHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: picker.picked(cell.iso)
            }
        }
    }
}
