pragma Singleton
import QtQuick

// Design tokens. The dark theme is matte black: flat neutral surfaces, no
// gradients, colour only where it carries meaning.
// Everything visual reads from here, so flipping `dark`
// re-themes the whole app through property bindings.
QtObject {
    property bool dark: true

    readonly property color bg: dark ? "#0A0A0A" : "#F3F4F7"
    readonly property color surface: dark ? "#121212" : "#FFFFFF"
    readonly property color surfaceAlt: dark ? "#1A1A1A" : "#ECEEF2"
    readonly property color border: dark ? "#242424" : "#DFE2E8"
    readonly property color text: dark ? "#EDEDED" : "#14171C"
    readonly property color textMuted: dark ? "#8F8F8F" : "#5F6878"
    readonly property color textFaint: dark ? "#5E5E5E" : "#99A1AF"

    readonly property color accent: dark ? "#4FCB96" : "#0C9467"
    readonly property color onAccent: dark ? "#06281B" : "#FFFFFF"
    // Buttons, selected chips and focus rings. Off-white on matte black, so the
    // green accent is kept for "done" and progress only.
    readonly property color primary: dark ? "#EDEDED" : accent
    readonly property color onPrimary: dark ? "#0A0A0A" : onAccent
    readonly property color danger: dark ? "#E5675F" : "#D43B30"
    readonly property color warn: dark ? "#D9A441" : "#B86E00"
    readonly property color info: dark ? "#7FA7D9" : "#2877CC"

    readonly property int radius: 14
    readonly property int fast: 140
    readonly property int normal: 220

    readonly property color shadow: dark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0.1, 0.13, 0.2, 0.05)

    function sectionName(status) {
        switch (status) {
        case "overdue": return qsTr("Overdue")
        case "today": return qsTr("Today")
        case "soon": return qsTr("Next 7 days")
        case "later": return qsTr("Later")
        case "done": return qsTr("Completed")
        default: return qsTr("No due date")
        }
    }

    function tint(c, alpha) {
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    // Opaque mix of `overlay` onto `base` (gradient stops cannot stack translucency).
    function tintOn(base, overlay, amount) {
        return Qt.rgba(base.r + (overlay.r - base.r) * amount,
                       base.g + (overlay.g - base.g) * amount,
                       base.b + (overlay.b - base.b) * amount, 1)
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
