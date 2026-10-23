import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Button {
    id: button
    property bool selected: false
    property string iconName: ""
    implicitHeight: 48
    leftPadding: 16
    rightPadding: 12
    focusPolicy: Qt.StrongFocus
    contentItem: RowLayout {
        spacing: 12
        NovaIcon {
            iconName: button.iconName
            implicitWidth: 20
            implicitHeight: 20
            color: button.selected ? Theme.accent : Theme.muted
        }
        Text {
            text: button.text
            font.pixelSize: Theme.body
            font.weight: button.selected ? Font.DemiBold : Font.Normal
            color: button.selected ? Theme.text : Theme.muted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
    background: Rectangle {
        radius: 12
        color: button.selected ? "#222c3e" : button.hovered ? Theme.surface : "transparent"
        border.color: button.activeFocus ? Theme.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Preferences.hoverDuration } }
        Rectangle {
            width: 3
            height: 18
            radius: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: button.selected
            color: Theme.accent
        }
    }
}

