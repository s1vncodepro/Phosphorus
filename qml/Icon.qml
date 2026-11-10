import QtQuick

// Small stroked vector icons drawn on a 24x24 grid, so no icon font or
// image assets have to ship with the app.
Canvas {
    id: icon

    property string name
    property color color: Theme.text
    property real strokeWidth: 1.9
    property int size: 18

    readonly property var paths: ({
        "check": "M5 12.5l4.5 4.5L19 7.5",
        "plus": "M12 5v14M5 12h14",
        "close": "M6.5 6.5l11 11M17.5 6.5l-11 11",
        "search": "M4.5 10.5a6 6 0 1 0 12 0a6 6 0 1 0 -12 0M15 15l4.5 4.5",
        "trash": "M4.5 7h15M9.5 7V4.5h5V7M6.5 7l1 12.5h9l1-12.5M10.2 10.5v5.5M13.8 10.5v5.5",
        "edit": "M4.5 19.5l1-4.5L16 4.5l3.5 3.5L9 18.5zM13.5 7l3.5 3.5",
        "calendar": "M6 5.5h12a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2H6a2 2 0 0 1 -2 -2v-10a2 2 0 0 1 2 -2M4 10h16M8.5 3.5v4M15.5 3.5v4",
        "left": "M14.5 6l-6 6l6 6",
        "right": "M9.5 6l6 6l-6 6",
        "sun": "M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4",
        "moon": "M20 14.2A8.2 8.2 0 1 1 9.8 4a6.6 6.6 0 0 0 10.2 10.2z",
        "sort": "M5 7h14M7.5 12h9M10 17h4",
        "list": "M9 7h10.5M9 12h10.5M9 17h10.5M4.5 7h.01M4.5 12h.01M4.5 17h.01",
        "circle": "M3.5 12a8.5 8.5 0 1 0 17 0a8.5 8.5 0 1 0 -17 0",
        "clock": "M3.5 12a8.5 8.5 0 1 0 17 0a8.5 8.5 0 1 0 -17 0M12 7.5V12l3 2",
        "alert": "M12 4.5L20.5 19h-17zM12 10.5v4M12 16.6h.01",
        "done": "M3.5 12a8.5 8.5 0 1 0 17 0a8.5 8.5 0 1 0 -17 0M8.3 12.3l2.6 2.6l4.8-5.2",
        "undo": "M8.5 5L4.5 9l4 4M4.5 9h9.5a5 5 0 0 1 0 10H9"
    })

    width: size
    height: size
    antialiasing: true

    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onSizeChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const d = paths[name]
        if (!d)
            return
        ctx.scale(width / 24, height / 24)
        ctx.lineWidth = strokeWidth
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.strokeStyle = color
        ctx.path = d
        ctx.stroke()
    }
}
