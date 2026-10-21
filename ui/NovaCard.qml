import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card
    default property alias content: layout.data
    property int padding: 24
    property alias spacing: layout.spacing
    implicitHeight: layout.implicitHeight + padding * 2
    implicitWidth: 280
    color: Theme.surface
    radius: 20
    border.color: Preferences.motionProfile === "cinematic" && !Preferences.reducedMotion
                  ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.border
    Behavior on border.color { ColorAnimation { duration: Preferences.hoverDuration } }
    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.padding
        spacing: 16
    }
}

