import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Add / edit form. An empty editId means "new assignment".
Popup {
    id: dialog

    property string editId: ""
    property string dueIso: ""
    property int priority: 1
    property bool calendarOpen: false
    signal removeRequested(string uid)

    function openNew() {
        editId = ""
        titleField.text = ""
        // Pre-fill the course when the list is filtered to one.
        courseField.text = assignments.course
        notesArea.text = ""
        dueIso = ""
        priority = 1
        begin()
    }

    function openEdit(uid) {
        const a = store.get(uid)
        if (a.uid === undefined)
            return
        editId = uid
        titleField.text = a.title
        courseField.text = a.course
        notesArea.text = a.notes
        dueIso = a.due
        priority = a.priority
        begin()
    }

    function begin() {
        titleField.invalid = false
        calendarOpen = false
        flick.contentY = 0
        open()
        titleField.forceActiveFocus()
    }

    function save() {
        if (titleField.text.trim().length === 0) {
            titleField.invalid = true
            titleField.forceActiveFocus()
            shake.restart()
            return
        }
        if (editId.length > 0)
            store.update(editId, titleField.text, courseField.text, dueIso, priority, notesArea.text)
        else
            store.add(titleField.text, courseField.text, dueIso, priority, notesArea.text)
        close()
    }

    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(parent.width - 24, 480)
    padding: 0
    modal: true
    focus: true
    // Not CloseOnPressOutside: a stray click should not throw away a half-filled form.
    closePolicy: Popup.CloseOnEscape

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, Theme.dark ? 0.6 : 0.35)
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: Theme.normal; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: Theme.fast }
            NumberAnimation { property: "scale"; to: 0.96; duration: Theme.fast }
        }
    }

    background: Rectangle {
        radius: 18
        color: Theme.surface
        border.width: 1
        border.color: Theme.tintOn(Theme.border, Theme.accent, 0.45)

        Glow { radius: parent.radius; spread: 12; strength: 0.8 }
    }

    component FieldLabel: Text {
        color: Theme.textMuted
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    component Chip: Rectangle {
        id: chip
        property string label
        property bool active: false
        property color tone: Theme.accent
        signal clicked()

        height: 30
        width: chipText.implicitWidth + 22
        radius: 15
        color: active ? Theme.tint(tone, 0.18) : chipHover.containsMouse ? Theme.border : Theme.surfaceAlt
        border.width: 1
        border.color: active ? Theme.tint(tone, 0.7) : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.fast } }

        Accessible.role: Accessible.Button
        Accessible.name: label

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.active ? chip.tone : Theme.textMuted
            font.pixelSize: 13
            font.weight: Font.Medium
        }
        MouseArea {
            id: chipHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    contentItem: Flickable {
        id: flick
        // Scrolls when the window is too short for the whole form.
        implicitHeight: Math.min(form.implicitHeight + 44, dialog.parent.height - 32)
        contentHeight: form.implicitHeight + 44
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { }

        ColumnLayout {
            id: form
            x: 22
            y: 22
            width: flick.width - 44
            spacing: 8

            transform: Translate { id: shakeOffset }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeOffset; property: "x"; to: -8; duration: 50 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 8; duration: 70 }
                NumberAnimation { target: shakeOffset; property: "x"; to: -4; duration: 60 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 50 }
            }

            RowLayout {
                Layout.bottomMargin: 6
                Text {
                    Layout.fillWidth: true
                    text: dialog.editId.length > 0 ? qsTr("Edit assignment") : qsTr("New assignment")
                    color: Theme.text
                    font.pixelSize: 19
                    font.weight: Font.Bold
                }
                PButton { iconName: "close"; tone: Theme.textMuted; tip: qsTr("Close"); onClicked: dialog.close() }
            }

            FieldLabel { text: qsTr("TITLE") }
            PTextField {
                id: titleField
                Layout.fillWidth: true
                placeholderText: qsTr("e.g. Chapter 4 problem set")
                maximumLength: 140
                onTextEdited: invalid = false
                onAccepted: dialog.save()
            }
            Text {
                visible: titleField.invalid
                text: qsTr("Give the assignment a title.")
                color: Theme.danger
                font.pixelSize: 12
            }

            FieldLabel { text: qsTr("COURSE"); Layout.topMargin: 8 }
            PTextField {
                id: courseField
                Layout.fillWidth: true
                placeholderText: qsTr("Optional, e.g. Biology")
                maximumLength: 60
                onAccepted: dialog.save()
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: store.courses.length > 0
                Repeater {
                    model: store.courses.slice(0, 6)
                    Chip {
                        required property string modelData
                        label: modelData
                        active: courseField.text.trim().toLowerCase() === modelData.toLowerCase()
                        onClicked: courseField.text = modelData
                    }
                }
            }

            FieldLabel { text: qsTr("DUE DATE"); Layout.topMargin: 8 }
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: Theme.surfaceAlt
                border.width: dialog.calendarOpen ? 2 : 1
                border.color: dialog.calendarOpen ? Theme.accent : Theme.border

                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Choose due date")

                Icon {
                    id: dueIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    name: "calendar"
                    color: Theme.textMuted
                }
                Text {
                    anchors.left: dueIcon.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: dialog.dueIso.length > 0 ? store.formatDate(dialog.dueIso) : qsTr("No due date")
                    color: dialog.dueIso.length > 0 ? Theme.text : Theme.textFaint
                    font.pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        calendar.reveal()
                        dialog.calendarOpen = !dialog.calendarOpen
                    }
                }
                PButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    anchors.verticalCenter: parent.verticalCenter
                    visible: dialog.dueIso.length > 0
                    iconName: "close"
                    tone: Theme.textMuted
                    tip: qsTr("Clear date")
                    onClicked: dialog.dueIso = ""
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [
                        { label: qsTr("Today"), days: 0 },
                        { label: qsTr("Tomorrow"), days: 1 },
                        { label: qsTr("In a week"), days: 7 }
                    ]
                    Chip {
                        required property var modelData
                        label: modelData.label
                        active: dialog.dueIso === store.addDaysIso(modelData.days)
                        onClicked: {
                            dialog.dueIso = store.addDaysIso(modelData.days)
                            calendar.reveal()
                        }
                    }
                }
            }
            // Calendar slides open under the date field.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: dialog.calendarOpen ? calendar.implicitHeight + 8 : 0
                clip: true
                Behavior on Layout.preferredHeight { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

                DatePicker {
                    id: calendar
                    width: parent.width
                    y: 4
                    value: dialog.dueIso
                    today: store.todayIso()
                    opacity: dialog.calendarOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                    onPicked: iso => {
                        dialog.dueIso = iso
                        dialog.calendarOpen = false
                    }
                }
            }

            FieldLabel { text: qsTr("PRIORITY"); Layout.topMargin: 8 }
            Row {
                spacing: 6
                Repeater {
                    model: 3
                    Chip {
                        required property int index
                        label: Theme.priorityName(index)
                        tone: index === 0 ? Theme.info : Theme.priorityColor(index)
                        active: dialog.priority === index
                        onClicked: dialog.priority = index
                    }
                }
            }

            FieldLabel { text: qsTr("NOTES"); Layout.topMargin: 8 }
            Rectangle {
                Layout.fillWidth: true
                height: 84
                radius: 10
                color: Theme.surfaceAlt
                border.width: notesArea.activeFocus ? 2 : 1
                border.color: notesArea.activeFocus ? Theme.accent : Theme.border

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 2
                    TextArea {
                        id: notesArea
                        placeholderText: qsTr("Optional details, links, page numbers…")
                        placeholderTextColor: Theme.textFaint
                        color: Theme.text
                        selectionColor: Theme.tint(Theme.accent, 0.35)
                        selectedTextColor: Theme.text
                        font.pixelSize: 14
                        wrapMode: TextArea.Wrap
                        selectByMouse: true
                        KeyNavigation.priority: KeyNavigation.BeforeItem
                        KeyNavigation.tab: saveButton
                        background: null
                    }
                }
            }

            RowLayout {
                Layout.topMargin: 14
                spacing: 8

                PButton {
                    visible: dialog.editId.length > 0
                    kind: "soft"
                    tone: Theme.danger
                    iconName: "trash"
                    text: qsTr("Delete")
                    onClicked: {
                        dialog.removeRequested(dialog.editId)
                        dialog.close()
                    }
                }
                Item { Layout.fillWidth: true }
                PButton { text: qsTr("Cancel"); tone: Theme.textMuted; onClicked: dialog.close() }
                PButton {
                    id: saveButton
                    kind: "primary"
                    text: dialog.editId.length > 0 ? qsTr("Save changes") : qsTr("Add assignment")
                    onClicked: dialog.save()
                }
            }
        }
    }
}
