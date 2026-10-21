import QtQuick

Rectangle {
    id: track
    property real value: 0
    property color fillColor: Theme.accent
    implicitHeight: 8
    implicitWidth: 160
    radius: 4
    color: "#2a3243"
    clip: true
    Rectangle {
        width: parent.width * Math.max(0, Math.min(100, track.value)) / 100
        height: parent.height
        radius: 4
        color: track.fillColor
        Behavior on width { NumberAnimation { duration: Preferences.hoverDuration; easing.type: Easing.OutCubic } }
    }
}
