import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Button {
    id: button
    property bool primary: false
    property string iconName: ""
    implicitHeight: 44
    implicitWidth: contentItem.implicitWidth + 32
    padding: 16
    focusPolicy: Qt.StrongFocus
    contentItem: RowLayout {
        spacing: 10
        NovaIcon {
            iconName: button.iconName
            visible: button.iconName !== ""
            implicitWidth: 18
            implicitHeight: 18
            color: button.primary ? Theme.onAccent : Theme.text
        }
        Text {
            text: button.text
            color: button.primary ? Theme.onAccent : Theme.text
            font.pixelSize: Theme.body
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
    background: Rectangle {
        radius: 12
        color: button.primary ? (button.down ? Qt.darker(Theme.accent, 1.15) : Theme.accent)
                              : (button.hovered ? "#2b3448" : Theme.raised)
        border.width: button.activeFocus ? 2 : 1
        border.color: button.activeFocus ? Theme.text : button.primary ? Theme.accent : Theme.border
        Behavior on color { ColorAnimation { duration: Preferences.hoverDuration } }
    }
    opacity: enabled ? 1 : 0.5
}

