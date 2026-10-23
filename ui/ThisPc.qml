import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 24
    function folderName(id) {
        const names = {home: ["Home", "Acasă"], desktop: ["Desktop", "Desktop"], documents: ["Documents", "Documente"],
            downloads: ["Downloads", "Descărcări"], pictures: ["Pictures", "Imagini"], music: ["Music", "Muzică"], videos: ["Videos", "Videoclipuri"]}
        const pair = names[id] || [id, id]
        return Theme.textFor(pair[0], pair[1])
    }
    Component.onCompleted: Workspace.refresh()
    RowLayout {
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            Text { text: Theme.textFor("This PC", "Acest PC"); color: Theme.text; font.pixelSize: Theme.heading; font.weight: Font.DemiBold }
            Text { text: Theme.textFor("Your files. A little more organized.", "Fișierele tale. Mai bine organizate."); color: Theme.muted; font.pixelSize: Theme.body }
        }
        NovaButton { text: Theme.textFor("Refresh", "Actualizează"); iconName: "view-refresh"; onClicked: Workspace.refresh() }
    }
    Text { text: Theme.textFor("QUICK ACCESS", "ACCES RAPID"); color: Theme.accent; font.pixelSize: Theme.small; font.letterSpacing: 1.5 }
    GridLayout {
        Layout.fillWidth: true
        columns: root.width > 760 ? 3 : 2
        rowSpacing: 12
        columnSpacing: 12
        Repeater {
            model: Workspace.folders
            delegate: Button {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 102
                Accessible.name: root.folderName(modelData.id)
                ToolTip.visible: hovered
                ToolTip.text: modelData.path
                onClicked: Workspace.openFolder(modelData.id)
                contentItem: RowLayout {
                    spacing: 14
                    NovaIcon { iconName: modelData.icon; implicitWidth: 32; implicitHeight: 32; color: Theme.accent }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: root.folderName(modelData.id); color: Theme.text; font.pixelSize: Theme.body; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: modelData.available ? Theme.textFor("Open folder", "Deschide folderul") : Theme.textFor("Not created yet", "Nu a fost creat"); color: Theme.muted; font.pixelSize: Theme.small }
                    }
                }
                padding: 20
                background: Rectangle { radius: 16; color: parent.hovered ? Theme.raised : Theme.surface; border.color: parent.activeFocus ? Theme.accent : Theme.border; Behavior on color { ColorAnimation { duration: Preferences.hoverDuration } } }
            }
        }
    }
    Text { text: Theme.textFor("DEVICES & STORAGE", "DISPOZITIVE ȘI STOCARE"); color: Theme.accent; font.pixelSize: Theme.small; font.letterSpacing: 1.5 }
    Repeater {
        model: Workspace.volumes
        delegate: NovaCard {
            required property var modelData
            Layout.fillWidth: true
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                NovaIcon { iconName: modelData.path === "/" ? "drive-harddisk" : "drive-removable-media"; implicitWidth: 36; implicitHeight: 36; color: Theme.accent }
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: modelData.name; color: Theme.text; font.pixelSize: 18; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Text { text: modelData.path + " · " + modelData.fileSystem + (modelData.readOnly ? Theme.textFor(" · Read only", " · Doar citire") : ""); color: Theme.muted; font.pixelSize: Theme.small; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
                }
                NovaButton { text: Theme.textFor("Open", "Deschide"); onClicked: Workspace.openVolume(modelData.path) }
            }
            MetricBar { Layout.fillWidth: true; value: modelData.usedPercent; fillColor: modelData.freeGiB < 8 ? "#f2c078" : Theme.accent }
            Text { text: Theme.textFor("%1 GiB free of %2 GiB", "%1 GiB liberi din %2 GiB").arg(modelData.freeGiB.toFixed(1)).arg(modelData.totalGiB.toFixed(1)); color: Theme.muted; font.pixelSize: Theme.body }
        }
    }
    Text { visible: Workspace.message !== ""; text: Workspace.message; color: "#f2c078"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    Text { text: Theme.textFor("NOVA stores personal files separately from the system image. Updates do not replace your home folder. Only mounted drives appear here.", "NOVA păstrează fișierele personale separat de imaginea sistemului. Actualizările nu înlocuiesc folderul personal. Aici apar doar discurile montate."); color: Theme.muted; font.pixelSize: Theme.small; wrapMode: Text.WordWrap; Layout.fillWidth: true }
}
