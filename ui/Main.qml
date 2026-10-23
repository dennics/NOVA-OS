import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ApplicationWindow {
    id: window
    width: initialWidth
    height: initialHeight
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    color: Theme.background
    title: "NOVA — " + Theme.textFor("Control Center", "Centrul de control")
    property int page: initialPage
    property bool showWelcome: welcomeMode
    readonly property var titles: [Theme.textFor("Overview", "Privire de ansamblu"), Theme.textFor("Personalization", "Personalizare"), Theme.textFor("Performance", "Performanță"), Theme.textFor("System & devices", "Sistem și dispozitive"), Theme.textFor("Updates", "Actualizări"), Theme.textFor("Driver Center", "Centrul de drivere"), Theme.textFor("This PC", "Acest PC"), Theme.textFor("Task Manager", "Task Manager")]
    function ensureFocusVisible() {
        const focus = activeFocusItem
        if (!focus) return
        let ancestor = focus
        while (ancestor && ancestor !== scroll.contentItem) ancestor = ancestor.parent
        if (!ancestor) return
        const position = focus.mapToItem(scroll.contentItem, 0, 0)
        let target = scroll.contentItem.contentY
        if (position.y < 16) target += position.y - 16
        else if (position.y + focus.height > scroll.availableHeight - 16)
            target += position.y + focus.height - scroll.availableHeight + 16
        scroll.contentItem.contentY = Math.max(0, Math.min(target, scroll.contentHeight - scroll.availableHeight))
    }
    onActiveFocusItemChanged: Qt.callLater(ensureFocusVisible)
    palette.window: Theme.background
    palette.windowText: Theme.text
    palette.base: Theme.surface
    palette.text: Theme.text
    palette.button: Theme.raised
    palette.buttonText: Theme.text
    palette.highlight: Theme.accent
    palette.highlightedText: Theme.onAccent

    Binding {
        target: Metrics
        property: "active"
        value: window.visible && window.visibility !== Window.Minimized && (window.page === 2 || window.page === 7) && !window.showWelcome
    }
    Binding {
        target: Processes
        property: "active"
        value: window.visible && window.visibility !== Window.Minimized && window.page === 7 && !window.showWelcome
    }
    Timer { interval: 60000; running: window.visible && window.visibility !== Window.Minimized && window.page === 4; repeat: true; onTriggered: Updates.refresh() }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.preferredWidth: window.width < 1000 ? 208 : 232
            Layout.fillHeight: true
            color: "#10131c"
            Rectangle { anchors.right: parent.right; height: parent.height; width: 1; color: Theme.border }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: window.height < 680 ? 4 : 8
                RowLayout {
                    Layout.topMargin: 12
                    Layout.bottomMargin: 20
                    spacing: 12
                    Image { source: "qrc:/assets/nova-mark.svg"; sourceSize.width: 40; sourceSize.height: 40; Layout.preferredWidth: 40; Layout.preferredHeight: 40 }
                    ColumnLayout {
                        spacing: 0
                        Text { text: "NOVA"; color: Theme.text; font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: 4 }
                        Text { text: "CONTROL CENTER"; color: Theme.muted; font.pixelSize: 9; font.letterSpacing: 1.8 }
                    }
                }
                Text { text: Theme.textFor("YOUR WORKSPACE", "SPAȚIUL TĂU"); color: "#68758e"; font.pixelSize: 10; font.letterSpacing: 1.5; Layout.leftMargin: 12; Layout.bottomMargin: 8 }
                Repeater {
                    model: ["view-dashboard", "preferences-desktop-theme-global", "preferences-system-power-management", "preferences-system", "system-software-update", "video-display", "computer", "utilities-system-monitor"]
                    delegate: NavItem {
                        implicitHeight: window.height < 680 ? 40 : 48
                        objectName: "nav-" + index
                        required property int index
                        required property string modelData
                        Layout.fillWidth: true
                        text: window.titles[index]
                        iconName: modelData
                        selected: window.page === index && !window.showWelcome
                        onClicked: { window.showWelcome = false; window.page = index }
                    }
                }
                Item { Layout.fillHeight: true }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border; Layout.bottomMargin: 12 }
                RowLayout {
                    spacing: 8
                    Rectangle { width: 6; height: 6; radius: 3; color: Theme.violet }
                    Text { text: "0.3 PREVIEW"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2 }
                }
                Text { text: "Your PC. Your Power."; color: "#68758e"; font.pixelSize: 11; Layout.topMargin: 4; Layout.bottomMargin: 8 }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 32
                    anchors.rightMargin: 32
                    Text {
                        text: window.showWelcome ? Theme.textFor("First steps", "Primii pași") : window.titles[window.page]
                        color: Theme.text
                        font.pixelSize: 18 * Theme.fontScale
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        implicitWidth: languageRow.implicitWidth + 8
                        implicitHeight: 36
                        radius: 10
                        color: Theme.surface
                        border.color: Theme.border
                        RowLayout {
                            id: languageRow
                            anchors.centerIn: parent
                            spacing: 2
                            Repeater {
                                model: ["ro", "en"]
                                delegate: Button {
                                    objectName: "language-" + modelData
                                    required property string modelData
                                    text: modelData.toUpperCase()
                                    implicitWidth: 36
                                    implicitHeight: 28
                                    Accessible.name: modelData === "ro" ? "Română" : "English"
                                    contentItem: Text { text: parent.text; color: Preferences.language === modelData ? Theme.text : Theme.muted; font.pixelSize: 11; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                    background: Rectangle { radius: 7; color: Preferences.language === modelData ? "#303b50" : "transparent"; border.color: parent.activeFocus ? Theme.accent : "transparent" }
                                    onClicked: Preferences.language = modelData
                                }
                            }
                        }
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
            }

            ScrollView {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: scroll.availableWidth
                    spacing: 20
                    Item { Layout.preferredHeight: 8 }
                    Kirigami.InlineMessage {
                        Layout.fillWidth: true
                        Layout.leftMargin: 32
                        Layout.rightMargin: 32
                        visible: SystemInfo.liveSession
                        text: Theme.textFor("Live session · Changes made here are temporary. Install NOVA to keep your files and settings.", "Sesiune Live · Modificările de aici sunt temporare. Instalează NOVA pentru a păstra fișierele și setările.")
                        type: Kirigami.MessageType.Information
                    }
                    Kirigami.InlineMessage {
                        Layout.fillWidth: true
                        Layout.leftMargin: 32
                        Layout.rightMargin: 32
                        visible: DesktopActions.error !== "" || Preferences.desktopError !== ""
                        text: Theme.textFor("This desktop component could not be opened or updated. Your NOVA preferences have been kept.", "Această componentă a desktopului nu a putut fi deschisă sau actualizată. Preferințele NOVA au fost păstrate.")
                        type: Kirigami.MessageType.Warning
                    }
                    Loader {
                        id: pageLoader
                        readonly property bool cinematicMotion: Preferences.motionProfile === "cinematic" && !Preferences.reducedMotion
                        Layout.fillWidth: true
                        Layout.leftMargin: 32
                        Layout.rightMargin: 32
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        sourceComponent: window.showWelcome ? welcomePage : window.page === 0 ? overviewPage : window.page === 1 ? appearancePage : window.page === 2 ? performancePage : window.page === 3 ? systemPage : window.page === 4 ? updatesPage : window.page === 5 ? driversPage : window.page === 6 ? thisPcPage : taskManagerPage
                        onCinematicMotionChanged: if (!cinematicMotion) { cinematicPulse.stop(); cinematicAccent.opacity = 0 }
                        onLoaded: {
                            scroll.contentItem.contentY = 0
                            cinematicPulse.stop()
                            cinematicAccent.opacity = 0
                            if (Preferences.animationsEnabled) {
                                opacity = 0
                                enterPage.restart()
                                if (cinematicMotion) cinematicPulse.restart()
                            }
                            else opacity = 1
                        }
                        NumberAnimation { id: enterPage; target: pageLoader; property: "opacity"; to: 1; duration: Preferences.panelDuration; easing.type: Easing.OutCubic }
                        Rectangle {
                            id: cinematicAccent
                            objectName: "cinematic-page-accent"
                            anchors.fill: parent
                            z: 1
                            radius: 20
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                            border.color: Theme.accent
                            border.width: 1
                            opacity: 0
                            visible: pageLoader.cinematicMotion
                        }
                        SequentialAnimation {
                            id: cinematicPulse
                            NumberAnimation { target: cinematicAccent; property: "opacity"; to: 0.6; duration: 80; easing.type: Easing.OutCubic }
                            NumberAnimation { target: cinematicAccent; property: "opacity"; to: 0; duration: 140; easing.type: Easing.OutCubic }
                        }
                    }
                    Item { Layout.preferredHeight: 24 }
                }
            }
        }
    }

    Dialog {
        id: restartDialog
        title: Theme.textFor("Restart NOVA?", "Repornești NOVA?")
        modal: true
        anchors.centerIn: parent
        width: 420
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: Updates.restart()
        contentItem: Text {
            text: Theme.textFor("Save your work first. The staged image or rollback will start after reboot.", "Salvează-ți lucrul. Imaginea pregătită sau revenirea se va activa după repornire.")
            color: Theme.text
            wrapMode: Text.WordWrap
            width: 360
        }
    }

    Component {
        id: overviewPage
        ColumnLayout {
            spacing: 24
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.max(228, heroText.implicitHeight + 56)
                radius: 20
                color: Theme.surface
                clip: true
                Image { anchors.fill: parent; source: "qrc:/assets/cosmic.svg"; fillMode: Image.PreserveAspectCrop; horizontalAlignment: Image.AlignRight; opacity: 0.8 }
                Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#151c2b" } GradientStop { position: 0.62; color: "#de151c2b" } GradientStop { position: 1; color: "#00151c2b" } } }
                ColumnLayout {
                    id: heroText
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 28
                    width: parent.width * 0.68
                    spacing: 12
                    Text { text: "NOVA OS"; color: Theme.accent; font.pixelSize: 11; font.letterSpacing: 3; font.bold: true }
                    Text { text: "Your PC.\nYour Power."; color: Theme.text; font.pixelSize: 38 * Theme.fontScale; font.weight: Font.DemiBold; lineHeight: 0.97; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Text { text: Theme.textFor("A space that feels like yours.", "Un spațiu pe gustul tău."); color: "#bdc9de"; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                NovaButton { Layout.fillWidth: true; text: Theme.textFor("This PC", "Acest PC"); iconName: "computer"; onClicked: window.page = 6 }
                NovaButton { Layout.fillWidth: true; text: Theme.textFor("Applications", "Aplicații"); iconName: "applications-all"; onClicked: DesktopActions.launch("apps") }
                NovaButton { Layout.fillWidth: true; text: Theme.textFor("Make it yours", "Personalizează"); primary: true; iconName: "preferences-desktop-theme-global"; onClicked: window.page = 1 }
            }
            GridLayout {
                Layout.fillWidth: true
                columns: width < 640 ? 1 : 2
                columnSpacing: 16
                rowSpacing: 16
                NovaCard {
                    Layout.fillWidth: true
                    Text { text: Theme.textFor("PROCESSOR", "PROCESOR"); color: Theme.muted; font.pixelSize: Theme.small; font.letterSpacing: 1.4 }
                    Text { text: SystemInfo.cpuName || Theme.textFor("Unavailable", "Indisponibil"); color: Theme.text; font.pixelSize: 19 * Theme.fontScale; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Text { text: Theme.textFor("Detected in this system", "Detectat în acest sistem"); color: Theme.muted; font.pixelSize: Theme.small }
                }
                NovaCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Text { text: Theme.textFor("SYSTEM MEMORY", "MEMORIE SISTEM"); color: Theme.muted; font.pixelSize: Theme.small; font.letterSpacing: 1.4 }
                    Text { text: SystemInfo.memoryCapacity || "—"; color: Theme.text; font.pixelSize: 30 * Theme.fontScale; font.weight: Font.DemiBold }
                    Text { text: Theme.textFor("Reported by the running system", "Raportată de sistemul pornit"); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
            }
            NovaCard {
                Layout.fillWidth: true
                Text { text: Theme.textFor("System status", "Starea sistemului"); color: Theme.text; font.pixelSize: 18 * Theme.fontScale; font.weight: Font.DemiBold }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 24
                    Text { text: "SELinux  ·  " + SystemInfo.selinux; color: SystemInfo.selinux === "enforcing" ? "#80d9b8" : "#f2c078"; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Text { text: "Firewall  ·  " + SystemInfo.firewall; color: SystemInfo.firewall === "active" ? "#80d9b8" : Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
                Text { text: SystemInfo.updateChannel ? Theme.textFor("Update channel: ", "Canal de actualizare: ") + SystemInfo.updateChannel : Theme.textFor("A NOVA update source has not been configured for this preview.", "Pentru această versiune preview nu este configurată o sursă de actualizări NOVA."); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                NovaButton { text: Theme.textFor("Refresh status", "Actualizează starea"); iconName: "view-refresh"; onClicked: SystemInfo.refreshStatus() }
            }
        }
    }

    Component {
        id: appearancePage
        ColumnLayout {
            spacing: 24
            Text { text: Theme.textFor("Make room for your style.", "Fă loc stilului tău."); color: Theme.text; font.pixelSize: Theme.heading; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Text { text: Theme.textFor("Cosmic colors. Thoughtful motion. Your NOVA.", "Culori cosmice. Mișcare fluidă. NOVA ta."); color: Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            NovaCard {
                Layout.fillWidth: true
                Text { text: Theme.textFor("Accent color", "Culoare de accent"); color: Theme.text; font.pixelSize: 18 * Theme.fontScale; font.weight: Font.DemiBold }
                Loader { Layout.fillWidth: true; Layout.preferredHeight: item ? item.implicitHeight : 0; sourceComponent: accentSelector }
                Rectangle {
                    id: motionCanvas
                    Layout.fillWidth: true
                    implicitHeight: 136
                    radius: 14
                    color: "#10141f"
                    clip: true
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 24; height: 1; color: Theme.border }
                    Rectangle {
                        id: motionTile
                        x: 24
                        anchors.verticalCenter: parent.verticalCenter
                        width: 112
                        height: 72
                        radius: 14
                        color: "#243047"
                        border.color: Theme.accent
                        border.width: 2
                        Image { anchors.centerIn: parent; width: 38; height: 38; source: "qrc:/assets/nova-mark.svg" }
                    }
                    SequentialAnimation {
                        id: motionPreview
                        NumberAnimation { target: motionTile; property: "x"; to: motionCanvas.width - motionTile.width - 24; duration: Preferences.panelDuration; easing.type: Easing.OutCubic }
                        PauseAnimation { duration: 160 }
                        NumberAnimation { target: motionTile; property: "x"; to: 24; duration: Preferences.panelDuration; easing.type: Easing.OutCubic }
                    }
                }
                NovaButton { text: Theme.textFor("Preview motion", "Previzualizează mișcarea"); iconName: "media-playback-start"; onClicked: motionPreview.restart() }
            }
            NovaCard {
                Layout.fillWidth: true
                Text { text: Theme.textFor("Motion profile", "Profil de animații"); color: Theme.text; font.pixelSize: 18 * Theme.fontScale; font.weight: Font.DemiBold }
                Loader { Layout.fillWidth: true; Layout.preferredHeight: item ? item.implicitHeight : 0; sourceComponent: motionSelector }
                Text { text: Theme.textFor("Minimal keeps transitions immediate. Balanced adds fluid movement. Cinematic adds luminous accents.", "Minimal afișează tranzițiile imediat. Balanced adaugă mișcare fluidă. Cinematic adaugă accente luminoase."); color: Theme.muted; font.pixelSize: Theme.body; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Switch { objectName: "reduced-motion"; text: Theme.textFor("Reduce motion", "Reducerea mișcării"); checked: Preferences.reducedMotion; onToggled: Preferences.reducedMotion = checked; font.pixelSize: Theme.body }
            }
            NovaCard {
                Layout.fillWidth: true
                Text { text: Theme.textFor("The sound of your orbit", "Sunetul orbitei tale"); color: Theme.text; font.pixelSize: 18; font.weight: Font.DemiBold }
                Text { text: Theme.textFor("Original short cues for sign-in, messages, devices and alerts. Preview a sound or choose your sound theme in KDE Settings.", "Sunete originale scurte pentru autentificare, mesaje, dispozitive și alerte. Ascultă un sunet sau alege tema sonoră din Setările KDE."); color: Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [{id: "desktop-login", en: "Sign-in", ro: "Autentificare"}, {id: "message-new-instant", en: "Message", ro: "Mesaj"}, {id: "device-added", en: "Device", ro: "Dispozitiv"}, {id: "complete", en: "Complete", ro: "Finalizare"}]
                        delegate: NovaButton { required property var modelData; text: Theme.textFor(modelData.en, modelData.ro); iconName: "media-playback-start"; onClicked: DesktopActions.previewSound(modelData.id) }
                    }
                }
                NovaButton { text: Theme.textFor("Sound theme settings", "Setările temei sonore"); iconName: "audio-volume-high"; onClicked: DesktopActions.launch("soundtheme") }
                NovaButton { text: Theme.textFor("Use NOVA Orbit sounds", "Folosește sunetele NOVA Orbit"); primary: true; onClicked: { Preferences.useNovaSounds(); DesktopActions.previewSound("desktop-login") } }
            }
        }
    }

    Component {
        id: performancePage
        ColumnLayout {
            spacing: 24
            NovaCard {
                Layout.fillWidth: true
                Text { text: Theme.textFor("Power profile", "Profil de energie"); color: Theme.text; font.pixelSize: 18 * Theme.fontScale; font.weight: Font.DemiBold }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [{value: "eco", en: "Eco", ro: "Eco"}, {value: "balanced", en: "Balanced", ro: "Balanced"}, {value: "gaming", en: "Gaming", ro: "Gaming"}]
                        delegate: NovaButton {
                            required property var modelData
                            Layout.fillWidth: true
                            text: Theme.textFor(modelData.en, modelData.ro)
                            primary: Profiles.profile === modelData.value
                            enabled: Profiles.available
                            onClicked: Profiles.setProfile(modelData.value)
                        }
                    }
                }
                Text { text: Theme.textFor("Eco saves power; Balanced adapts; Gaming requests the system's performance profile when supported. GameMode activates per game when launched with gamemoderun.", "Eco economisește energie; Balanced se adaptează; Gaming cere profilul de performanță când hardware-ul îl permite. GameMode se activează pentru fiecare joc lansat cu gamemoderun."); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Text { visible: Profiles.message !== ""; text: Profiles.message; color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                NovaButton { text: Theme.textFor("Refresh profile", "Verifică profilul"); iconName: "view-refresh"; onClicked: Profiles.refresh() }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: Theme.textFor("A clearer view of your PC.", "Vezi ce face calculatorul tău."); color: Theme.text; font.pixelSize: Theme.heading; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Rectangle { width: 7; height: 7; radius: 4; color: Metrics.active ? "#80d9b8" : Theme.muted }
                Text { text: Metrics.active ? Theme.textFor("LIVE", "ÎN DIRECT") : Theme.textFor("PAUSED", "ÎN PAUZĂ"); color: Theme.muted; font.pixelSize: Theme.small; font.letterSpacing: 1 }
            }
            NovaCard {
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: Theme.textFor("Processor", "Procesor"); color: Theme.text; font.pixelSize: 18 * Theme.fontScale; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    Text { text: Metrics.cpuValid ? Metrics.cpuPercent.toFixed(1) + "%" : "—"; color: Theme.accent; font.pixelSize: 32 * Theme.fontScale; font.weight: Font.DemiBold }
                }
                MetricBar { Layout.fillWidth: true; value: Metrics.cpuValid ? Metrics.cpuPercent : 0 }
                Text { text: SystemInfo.cpuName || Theme.textFor("CPU data unavailable", "Date CPU indisponibile"); color: Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
            NovaCard {
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: Theme.textFor("Memory", "Memorie"); color: Theme.text; font.pixelSize: 18 * Theme.fontScale; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    Text { text: Metrics.memoryValid ? Metrics.memoryPercent.toFixed(1) + "%" : "—"; color: Theme.violet; font.pixelSize: 32 * Theme.fontScale; font.weight: Font.DemiBold }
                }
                MetricBar { Layout.fillWidth: true; value: Metrics.memoryValid ? Metrics.memoryPercent : 0; fillColor: Theme.violet }
                Text { text: Metrics.memoryValid ? Metrics.memoryUsedGiB.toFixed(2) + " / " + Metrics.memoryTotalGiB.toFixed(2) + " GiB" : Theme.textFor("Memory data unavailable", "Date de memorie indisponibile"); color: Theme.muted; font.pixelSize: Theme.body }
                Text { text: Theme.textFor("Available memory includes cache the system can reclaim when needed.", "Memoria disponibilă include cache-ul pe care sistemul îl poate recupera la nevoie."); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
            Text { text: Theme.textFor("Refreshes once per second while this page is visible. Sampling pauses when you leave it or minimize the window.", "Datele se actualizează o dată pe secundă cât pagina este vizibilă. Citirea se oprește când părăsești pagina sau minimizezi fereastra."); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        }
    }

    Component {
        id: systemPage
        ColumnLayout {
            spacing: 24
            Text { text: Theme.textFor("Everything in its place.", "Totul la locul lui."); color: Theme.text; font.pixelSize: Theme.heading; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            NovaCard {
                Layout.fillWidth: true
                Text { text: SystemInfo.operatingSystem; color: Theme.text; font.pixelSize: 20 * Theme.fontScale; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Text { text: "Linux " + SystemInfo.kernel; color: Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
            GridLayout {
                Layout.fillWidth: true
                columns: width < 640 ? 1 : 2
                columnSpacing: 16
                rowSpacing: 16
                Repeater {
                    model: [
                        { action: "display", icon: "preferences-desktop-display", en: "Display", ro: "Ecran" },
                        { action: "sound", icon: "audio-volume-high", en: "Sound", ro: "Sunet" },
                        { action: "network", icon: "network-wireless", en: "Network", ro: "Rețea" },
                        { action: "bluetooth", icon: "preferences-system-bluetooth", en: "Bluetooth", ro: "Bluetooth" },
                        { action: "power", icon: "preferences-system-power-management", en: "Power", ro: "Alimentare" },
                        { action: "accessibility", icon: "preferences-desktop-accessibility", en: "Accessibility", ro: "Accesibilitate" }
                    ]
                    delegate: NovaButton {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 64
                        text: Theme.textFor(modelData.en, modelData.ro)
                        iconName: modelData.icon
                        onClicked: DesktopActions.launch(modelData.action)
                    }
                }
            }
            NovaButton { text: Theme.textFor("All system settings", "Toate setările sistemului"); iconName: "preferences-system"; onClicked: DesktopActions.launch("settings") }
        }
    }

    Component {
        id: updatesPage
        UpdatesPage { onRestartRequested: restartDialog.open() }
    }

    Component {
        id: driversPage
        ColumnLayout {
            spacing: 20
            Text { text: Theme.textFor("NOVA Driver Center", "Centrul de drivere NOVA"); color: Theme.text; font.pixelSize: Theme.heading; font.weight: Font.DemiBold }
            Text { text: Theme.textFor("GPU detection and the active Linux driver. Driver updates arrive with a validated NOVA system image.", "Detectarea GPU-ului și a driverului Linux activ. Actualizările driverelor sosesc printr-o imagine NOVA validată."); color: Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Repeater {
                model: Drivers.devices
                delegate: NovaCard {
                    required property var modelData
                    Layout.fillWidth: true
                    Text { text: modelData.vendor + " GPU  ·  " + modelData.address; color: Theme.text; font.pixelSize: 18 * Theme.fontScale; font.weight: Font.DemiBold }
                    Text { text: Theme.textFor("Device", "Dispozitiv") + ": " + modelData.deviceId + "  ·  " + Theme.textFor("Active driver", "Driver activ") + ": " + modelData.driver; color: Theme.accent; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Text { text: modelData.guidance; color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
            }
            Text { visible: Drivers.message !== ""; text: Drivers.message; color: Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Text { text: Theme.textFor("Proprietary NVIDIA installation is pending validation of a trusted package source and Secure Boot. NVIDIA App for Windows is not used.", "Instalarea NVIDIA proprietară așteaptă validarea unei surse de pachete de încredere și a Secure Boot. NVIDIA App pentru Windows nu este utilizată."); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            RowLayout {
                Layout.fillWidth: true
                NovaButton { Layout.fillWidth: true; text: Theme.textFor("Refresh devices", "Redetectează dispozitivele"); iconName: "view-refresh"; onClicked: Drivers.refresh() }
                NovaButton { Layout.fillWidth: true; text: Theme.textFor("System updates", "Actualizări sistem"); iconName: "system-software-update"; onClicked: window.page = 4 }
            }
        }
    }

    Component {
        id: thisPcPage
        ThisPc {}
    }
    Component {
        id: taskManagerPage
        TaskManager {}
    }
    Component {
        id: welcomePage
        ColumnLayout {
            spacing: 24
            Image { source: "qrc:/assets/nova-mark.svg"; Layout.preferredWidth: 72; Layout.preferredHeight: 72; sourceSize.width: 144; sourceSize.height: 144 }
            Text { text: Theme.textFor("Welcome to your NOVA.", "Bun venit în NOVA ta."); color: Theme.text; font.pixelSize: Theme.heading; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Text { text: Theme.textFor("Choose your accent and the way your desktop moves. You can change them at any time.", "Alege culoarea și felul în care se mișcă desktopul tău. Le poți schimba oricând."); color: Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            NovaCard {
                Layout.fillWidth: true
                Text { text: Theme.textFor("Your accent", "Culoarea ta"); color: Theme.text; font.pixelSize: 18 * Theme.fontScale; font.weight: Font.DemiBold }
                Loader { Layout.fillWidth: true; Layout.preferredHeight: item ? item.implicitHeight : 0; sourceComponent: accentSelector }
                Text { text: Theme.textFor("Your motion", "Animațiile tale"); color: Theme.text; font.pixelSize: 18 * Theme.fontScale; font.weight: Font.DemiBold; Layout.topMargin: 12 }
                Loader { Layout.fillWidth: true; Layout.preferredHeight: item ? item.implicitHeight : 0; sourceComponent: motionSelector }
                Switch { text: Theme.textFor("Reduce motion", "Reducerea mișcării"); checked: Preferences.reducedMotion; onToggled: Preferences.reducedMotion = checked; font.pixelSize: Theme.body }
            }
            Text { text: Theme.textFor("Your preferences stay on this computer. No online account is needed.", "Preferințele rămân pe acest calculator. Nu este necesar un cont online."); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Text { text: Theme.textFor("The language of other desktop applications applies at your next sign-in.", "Limba celorlalte aplicații se aplică la următoarea autentificare."); color: Theme.muted; font.pixelSize: Theme.small; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            NovaButton { text: Theme.textFor("Enter NOVA", "Intră în NOVA"); iconName: "go-next"; primary: true; onClicked: { Preferences.completeWelcome(); window.showWelcome = false; if (welcomeMode) window.close() } }
        }
    }

    Component {
        id: accentSelector
        RowLayout {
            spacing: 12
            Repeater {
                model: [
                    { value: "#57c7ff", en: "Electric blue", ro: "Albastru electric" },
                    { value: "#9775ff", en: "Cosmic violet", ro: "Violet cosmic" },
                    { value: "#64dfb8", en: "Aurora green", ro: "Verde auroral" },
                    { value: "#ff9a76", en: "Solar orange", ro: "Portocaliu solar" },
                    { value: "#ef8fc6", en: "Nebula pink", ro: "Roz nebular" },
                    { value: "#dbe8ff", en: "Starlight", ro: "Lumină stelară" }
                ]
                delegate: RoundButton {
                    required property var modelData
                    implicitWidth: 44
                    implicitHeight: 44
                    Accessible.name: Theme.textFor(modelData.en, modelData.ro)
                    Accessible.checkable: true
                    Accessible.checked: Preferences.accent === modelData.value
                    ToolTip.visible: hovered
                    ToolTip.text: Accessible.name
                    contentItem: Text { text: Preferences.accent === modelData.value ? "✓" : ""; color: Theme.onAccent; font.pixelSize: 20; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: modelData.value; radius: 22; border.width: parent.activeFocus ? 3 : 1; border.color: parent.activeFocus ? Theme.text : Qt.darker(modelData.value, 1.2) }
                    onClicked: Preferences.accent = modelData.value
                }
            }
            Item { Layout.fillWidth: true }
        }
    }

    Component {
        id: motionSelector
        RowLayout {
            spacing: 8
            Repeater {
                model: ["minimal", "balanced", "cinematic"]
                delegate: NovaButton {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    primary: Preferences.motionProfile === modelData
                    onClicked: Preferences.motionProfile = modelData
                }
            }
        }
    }
}
