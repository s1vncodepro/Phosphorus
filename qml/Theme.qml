pragma Singleton
import QtQuick

// Design tokens. Everything visual reads from here, so flipping `dark`
// re-themes the whole app through property bindings.
QtObject {
    property bool dark: true

    readonly property color bg: dark ? "#0D0F13" : "#F3F4F7"
    readonly property color surface: dark ? "#15181E" : "#FFFFFF"
    readonly property color surfaceAlt: dark ? "#1C2028" : "#ECEEF2"
    readonly property color border: dark ? "#252A34" : "#DFE2E8"
    readonly property color text: dark ? "#EDEFF3" : "#14171C"
    readonly property color textMuted: dark ? "#8D95A5" : "#5F6878"
    readonly property color textFaint: dark ? "#5C6474" : "#99A1AF"

    readonly property color accent: dark ? "#3DDC97" : "#0C9467"
    readonly property color onAccent: dark ? "#06281B" : "#FFFFFF"
    readonly property color danger: dark ? "#FF6B6B" : "#D43B30"
    readonly property color warn: dark ? "#FFB454" : "#B86E00"
    readonly property color info: dark ? "#6CB2FF" : "#2877CC"

    readonly property int radius: 14
    readonly property int fast: 140
    readonly property int normal: 220

    function tint(c, alpha) {
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    function statusColor(status) {
        switch (status) {
        case "overdue": return danger
        case "today": return warn
        case "soon": return info
        case "done": return accent
        default: return textMuted
        }
    }

    function priorityColor(priority) {
        return priority === 2 ? danger : priority === 1 ? warn : textFaint
    }

    function priorityName(priority) {
        return priority === 2 ? qsTr("High") : priority === 1 ? qsTr("Medium") : qsTr("Low")
    }
}
