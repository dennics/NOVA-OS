// SPDX-License-Identifier: MIT
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.textColor: "#f3f5fa"
    Kirigami.Theme.backgroundColor: "#101522"
    Plasmoid.icon: "nova-control-center"
    toolTipMainText: "NOVA Start"
    toolTipSubText: i18n("Applications, files and your workspace")
    switchWidth: Kirigami.Units.gridUnit * 20
    switchHeight: Kirigami.Units.gridUnit * 20
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation
    property string query: ""
    property bool allApplications: false
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property var searchResults: searchModel.count > 0 ? searchModel.modelForRow(0) : null
    onExpandedChanged: {
        if (expanded) { query = ""; allApplications = false; if (fullRepresentationItem) fullRepresentationItem.focusSearch() }
    }
    Kicker.AppsModel {
        id: applications
        flat: true
        sorted: true
        showSeparators: false
        appNameFormat: 0
        appletInterface: root
    }
    Kicker.SimpleFavoritesModel { id: pinned; favorites: Plasmoid.configuration.pinnedApps }
    Kicker.SimpleFavoritesModel { id: sessionActions; favorites: ["lock-screen", "logout", "reboot", "shutdown"] }
    Kicker.RunnerModel {
        id: searchModel
        query: root.query
        appletInterface: root
        runners: ["krunner_services", "krunner_systemsettings"]
        mergeResults: true
    }
    compactRepresentation: Controls.ToolButton {
        Accessible.name: "NOVA Start"
        text: "NOVA Start"
        display: Controls.AbstractButton.IconOnly
        icon.name: "nova-control-center"
        icon.width: 32
        icon.height: 32
        onClicked: root.expanded = !root.expanded
        background: Rectangle { radius: 12; color: parent.hovered || root.expanded ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18) : "transparent" }
    }
    fullRepresentation: FocusScope {
        id: menu
        Layout.minimumWidth: 580
        Layout.minimumHeight: 520
        Layout.preferredWidth: 660
        Layout.preferredHeight: 570
        function focusSearch() { search.forceActiveFocus() }
        Component.onCompleted: focusSearch()
        Keys.onEscapePressed: root.expanded = false
        Rectangle {
            anchors.fill: parent
            color: "#101522"
            radius: 20
            border.color: "#303b52"
            Rectangle { width: parent.width * 0.48; height: 2; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; color: root.accent; radius: 1 }
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                Kirigami.Icon { source: "nova-control-center"; implicitWidth: 34; implicitHeight: 34 }
                ColumnLayout {
                    spacing: 2
                    Controls.Label { text: "NOVA"; color: "#f3f5fa"; font.pixelSize: 20; font.bold: true; font.letterSpacing: 4 }
                    Controls.Label { text: i18n("YOUR ORBIT"); color: "#a4aec2"; font.pixelSize: 9; font.letterSpacing: 2 }
                }
                Item { Layout.fillWidth: true }
                Controls.Label { text: "0.3 PREVIEW"; color: root.accent; font.pixelSize: 10; font.letterSpacing: 1 }
            }
            Controls.TextField {
                id: search
                Layout.fillWidth: true
                implicitHeight: 44
                placeholderText: i18n("Search your applications…")
                color: "#f3f5fa"
                placeholderTextColor: "#a4aec2"
                selectionColor: root.accent
                selectedTextColor: "#0b0d14"
                leftPadding: 14
                background: Rectangle { radius: 12; color: "#1b2334"; border.color: search.activeFocus ? root.accent : "#303b52" }
                Accessible.name: placeholderText
                text: root.query
                onTextEdited: root.query = text
                Keys.onDownPressed: { grid.currentIndex = 0; grid.forceActiveFocus() }
                onAccepted: {
                    const target = root.query ? root.searchResults : root.allApplications ? applications : pinned
                    if (target && target.count > 0 && target.trigger(0, "", null)) root.expanded = false
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Controls.Label { text: root.query ? i18n("SEARCH RESULTS") : root.allApplications ? i18n("ALL APPLICATIONS") : i18n("PINNED TO YOUR ORBIT"); color: "#a4aec2"; font.pixelSize: 10; font.letterSpacing: 1.5; Layout.fillWidth: true }
                Controls.ToolButton {
                    visible: root.query === ""
                    text: root.allApplications ? i18n("Pinned") : i18n("All apps")
                    contentItem: Controls.Label { text: parent.text; color: root.accent; horizontalAlignment: Text.AlignHCenter }
                    onClicked: root.allApplications = !root.allApplications
                }
            }
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / 4)
                cellHeight: 104
                model: root.query ? root.searchResults : root.allApplications ? applications : pinned
                keyNavigationEnabled: true
                activeFocusOnTab: true
                Controls.ScrollBar.vertical: Controls.ScrollBar {}
                delegate: Controls.Button {
                    required property var model
                    required property int index
                    width: grid.cellWidth - 8
                    height: 96
                    text: model.display || ""
                    Accessible.name: text
                    focusPolicy: Qt.StrongFocus
                    onClicked: if (grid.model.trigger(index, "", null)) root.expanded = false
                    contentItem: ColumnLayout {
                        spacing: 10
                        Kirigami.Icon { source: model.decoration; color: "#dbe8ff"; Layout.alignment: Qt.AlignHCenter; implicitWidth: 34; implicitHeight: 34 }
                        Controls.Label { text: parent.parent.text; color: "#f3f5fa"; font.pixelSize: 11; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
                    }
                    background: Rectangle { radius: 14; color: parent.hovered || parent.activeFocus ? "#263047" : "transparent"; border.color: parent.activeFocus ? root.accent : "transparent"; Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } } }
                    Keys.onReturnPressed: clicked()
                }
                Keys.onUpPressed: event => { if (currentIndex < 4) search.forceActiveFocus(); else event.accepted = false }
                Controls.Label { anchors.centerIn: parent; visible: root.query !== "" && !searchModel.querying && grid.count === 0; text: i18n("No applications found"); color: "#a4aec2" }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: "#303b52" }
            RowLayout {
                Layout.fillWidth: true
                Controls.Label { text: "Your PC. Your Power."; color: "#a4aec2"; font.pixelSize: 11; Layout.fillWidth: true }
                Repeater {
                    model: sessionActions
                    delegate: Controls.ToolButton {
                        required property var model
                        required property int index
                        text: model.display || ""
                        icon.name: model.decoration || ""
                        display: Controls.AbstractButton.IconOnly
                        Accessible.name: text
                        contentItem: Kirigami.Icon { source: model.decoration; color: "#dbe8ff"; isMask: true; implicitWidth: 20; implicitHeight: 20 }
                        Controls.ToolTip.visible: hovered
                        Controls.ToolTip.text: text
                        onClicked: { sessionActions.trigger(index, "", null); root.expanded = false }
                    }
                }
            }
        }
    }
}
