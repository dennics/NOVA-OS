import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 20
    signal restartRequested()
    Component.onCompleted: Updates.refresh()
    Text { text: Theme.textFor("NOVA Update", "NOVA Update"); color: Theme.text; font.pixelSize: Theme.heading; font.weight: Font.DemiBold }
    Text { text: Theme.textFor("A fresh NOVA. Your files stay yours.", "O versiune nouă de NOVA. Aceleași fișiere personale."); color: Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
    NovaCard {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            NovaIcon { iconName: Updates.restartRequired ? "system-reboot" : "system-software-update"; implicitWidth: 42; implicitHeight: 42; color: Theme.accent }
            ColumnLayout {
                Layout.fillWidth: true
                Text {
                    text: Updates.liveSystem ? Theme.textFor("Available after installation", "Disponibil după instalare")
                        : Updates.restartRequired ? Theme.textFor("Ready to restart", "Pregătit pentru repornire")
                        : Updates.updateAvailable ? Theme.textFor("An update is available", "Este disponibilă o actualizare")
                        : Theme.textFor("Your NOVA system", "Sistemul tău NOVA")
                    color: Theme.text; font.pixelSize: 22; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; Layout.fillWidth: true
                }
                Text { text: Theme.textFor("Installed version: ", "Versiune instalată: ") + (Updates.currentVersion || SystemInfo.operatingSystem); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Text { visible: Updates.availableVersion !== ""; text: Theme.textFor("Available: ", "Disponibilă: ") + Updates.availableVersion; color: Theme.accent; font.pixelSize: Theme.small }
                Text { visible: Updates.staged; text: Theme.textFor("Next restart: ", "La următoarea repornire: ") + (Updates.stagedVersion || "NOVA") + (Updates.downloadOnly ? Theme.textFor(" · Downloaded, awaiting installation", " · Descărcată, așteaptă instalarea") : ""); color: Theme.accent; font.pixelSize: Theme.small; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
        }
        BusyIndicator { running: Updates.busy; visible: running; Layout.alignment: Qt.AlignHCenter; implicitHeight: 36; implicitWidth: 36 }
        Text { text: Updates.message; textFormat: Text.PlainText; color: Theme.muted; font.pixelSize: Theme.small; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RowLayout {
            Layout.fillWidth: true
            NovaButton { objectName: "check-updates"; Layout.fillWidth: true; text: Theme.textFor("Check for updates", "Caută actualizări"); iconName: "view-refresh"; enabled: Updates.sourceReady && !Updates.busy; onClicked: Updates.check() }
            NovaButton { objectName: "install-updates"; Layout.fillWidth: true; text: Theme.textFor("Download & install", "Descarcă și instalează"); iconName: "system-software-update"; primary: true; enabled: Updates.sourceReady && !Updates.busy; onClicked: Updates.install() }
        }
        NovaButton { visible: Updates.restartRequired; text: Theme.textFor("Restart when ready", "Repornește când ești pregătit"); iconName: "system-reboot"; enabled: !Updates.busy; onClicked: root.restartRequested() }
    }
    NovaCard {
        Layout.fillWidth: true
        visible: Updates.channelMigrationAvailable
        Text { text: Theme.textFor("Connect future NOVA releases", "Conectează versiunile NOVA viitoare"); color: Theme.text; font.pixelSize: 18; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Text { text: Theme.textFor("This installation follows an old fixed image or a placeholder source. Connect it once to NOVA Preview to receive future published versions from Settings. This downloads a system image and needs a restart. Your home folder is kept.", "Această instalare urmărește o imagine veche fixă sau o sursă provizorie. Conecteaz-o o singură dată la NOVA Preview pentru a primi versiunile viitoare publicate direct din Setări. Se descarcă o imagine de sistem și va fi necesară repornirea. Folderul personal este păstrat."); color: Theme.muted; font.pixelSize: Theme.body; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        NovaButton { text: Theme.textFor("Connect NOVA Preview", "Conectează NOVA Preview"); primary: true; enabled: !Updates.busy; onClicked: channelDialog.open() }
    }
    NovaCard {
        Layout.fillWidth: true
        Text { text: Theme.textFor("Update channel", "Canal de actualizare"); color: Theme.text; font.pixelSize: 18; font.weight: Font.DemiBold }
        Text { text: Updates.source || Theme.textFor("No source detected", "Nicio sursă detectată"); color: Theme.accent; font.pixelSize: Theme.small; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
        Text { text: Theme.textFor("NOVA checks image metadata every six hours. Downloads and installation start only when you request them. Save your work before restarting. Preview releases are experimental.", "NOVA verifică metadatele imaginii la șase ore. Descărcarea și instalarea pornesc la cererea ta. Salvează-ți lucrul înainte de repornire. Versiunile Preview sunt experimentale."); color: Theme.muted; font.pixelSize: Theme.small; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RowLayout {
            NovaButton { text: Theme.textFor("App updates", "Actualizări aplicații"); iconName: "applications-all"; onClicked: DesktopActions.launch("apps") }
            NovaButton { text: Theme.textFor("Refresh status", "Verifică starea"); enabled: !Updates.busy; onClicked: Updates.refresh() }
        }
    }
    NovaCard {
        Layout.fillWidth: true
        Text { text: Theme.textFor("Recovery", "Recuperare"); color: Theme.text; font.pixelSize: 18; font.weight: Font.DemiBold }
        Text { text: Updates.rollbackAvailable ? Theme.textFor("Previous version: ", "Versiune anterioară: ") + (Updates.rollbackVersion || Theme.textFor("Available", "Disponibilă")) : Theme.textFor("A previous deployment is not available yet.", "Nu există încă o versiune anterioară disponibilă."); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        NovaButton { text: Theme.textFor("Return to previous version", "Revino la versiunea anterioară"); enabled: Updates.rollbackAvailable && !Updates.busy; onClicked: rollbackDialog.open() }
    }
    NovaCard {
        Layout.fillWidth: true
        visible: Updates.details !== ""
        Text { text: Theme.textFor("Operation details", "Detaliile operațiunii"); color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
        TextArea { Layout.fillWidth: true; Layout.preferredHeight: 180; readOnly: true; selectByMouse: true; text: Updates.details; wrapMode: TextEdit.WrapAnywhere; font.family: "monospace"; font.pixelSize: 11; color: Theme.muted }
    }
    Dialog {
        id: channelDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(450, parent.width - 40)
        modal: true
        title: Theme.textFor("Connect NOVA Preview?", "Conectezi NOVA Preview?")
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: Label { text: Theme.textFor("Future images will be downloaded from ghcr.io/dennics/nova-os:preview. Administrative authentication is required. The current running version remains active until restart.", "Versiunile viitoare vor fi descărcate din ghcr.io/dennics/nova-os:preview. Este necesară autentificarea administrativă. Versiunea pornită rămâne activă până la repornire."); wrapMode: Text.WordWrap }
        onAccepted: Updates.enablePreviewChannel()
    }
    Dialog {
        id: rollbackDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(450, parent.width - 40)
        modal: true
        title: Theme.textFor("Select the previous version?", "Selectezi versiunea anterioară?")
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: Label { text: Theme.textFor("The previous system will start after your next restart. Personal files are kept; application settings may have changed between versions.", "Sistemul anterior va porni după următoarea repornire. Fișierele personale sunt păstrate; setările aplicațiilor se pot fi schimbat între versiuni."); wrapMode: Text.WordWrap }
        onAccepted: Updates.rollback()
    }
}
