import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 780
    height: 620
    minimumWidth: 620
    minimumHeight: 500
    visible: true
    title: "NOVA Smart Compatibility"
    color: "#0b0d14"

    readonly property color ink: "#f3f5fa"
    readonly property color muted: "#a4aec2"
    readonly property color blue: "#57c7ff"
    readonly property color violet: "#9775ff"
    readonly property bool ro: Compatibility.romanian
    function tr(en, romanian) { return ro ? romanian : en }
    function issueText() {
        if (Compatibility.problem === "unreadable") return tr("The file is missing or cannot be read.", "Fișierul lipsește sau nu poate fi citit.")
        if (Compatibility.problem === "extension") return tr("Choose a Windows .exe file.", "Alege un fișier Windows .exe.")
        if (Compatibility.problem === "not-pe") return tr("This is not a valid Windows PE executable.", "Acesta nu este un executabil Windows PE valid.")
        if (Compatibility.problem === "not-executable") return tr("This PE file is a DLL or is not marked executable.", "Acest fișier PE este un DLL sau nu este marcat ca executabil.")
        if (Compatibility.problem === "architecture") return tr("This processor type is not supported by the bundled Wine setup.", "Acest tip de procesor nu este acceptat de configurația Wine inclusă.")
        if (Compatibility.problem === "wine-missing") return tr("Wine is not installed on this system.", "Wine nu este instalat pe acest sistem.")
        return tr("Wine can try to start this program. Compatibility is unverified.", "Wine poate încerca să pornească acest program. Compatibilitatea nu este verificată.")
    }
    function launchText() {
        if (Compatibility.launchStatus === "started") return tr("Wine started. Whether this program works is still unknown.", "Wine a pornit. Nu știm încă dacă programul funcționează.")
        if (Compatibility.launchStatus === "failed") return tr("Wine could not be started.", "Wine nu a putut fi pornit.")
        if (Compatibility.launchStatus === "unavailable") return tr("The file or Wine is no longer available.", "Fișierul sau Wine nu mai este disponibil.")
        return ""
    }

    background: Rectangle {
        color: "#0b0d14"
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: root.violet
            opacity: 0.75
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 18

        RowLayout {
            spacing: 16
            Rectangle {
                width: 54; height: 54; radius: 16
                color: "#182438"
                border.color: root.violet
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "✦"
                    color: root.blue
                    font.pixelSize: 36
                }
            }
            ColumnLayout {
                spacing: 3
                Text {
                    text: "NOVA Smart Compatibility"
                    color: root.ink
                    font.pixelSize: 25
                    font.weight: Font.DemiBold
                }
                Text {
                    text: root.tr("Check a Windows program before you run it", "Verifică programul Windows înainte să îl rulezi")
                    color: root.muted
                    font.pixelSize: 13
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a3243" }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: Compatibility.fileName || root.tr("No file selected", "Niciun fișier selectat")
                color: root.ink
                font.pixelSize: 19
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
            Text {
                text: Compatibility.filePath
                color: root.muted
                font.pixelSize: 12
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width - 8
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: fileColumn.implicitHeight + 28
                    radius: 14
                    color: "#151923"
                    border.color: "#2a3243"
                    ColumnLayout {
                        id: fileColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 5
                        Text { text: root.tr("WINDOWS FILE", "FIȘIER WINDOWS"); color: root.violet; font.pixelSize: 11; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: Compatibility.validPe
                                ? root.tr("PE executable · " + Compatibility.architecture, "Executabil PE · " + Compatibility.architecture)
                                : root.issueText()
                            color: root.ink
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: wineColumn.implicitHeight + 28
                    radius: 14
                    color: "#151923"
                    border.color: Compatibility.canAttempt ? root.blue : "#2a3243"
                    ColumnLayout {
                        id: wineColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 5
                        Text { text: "WINE"; color: root.blue; font.pixelSize: 11; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: root.issueText()
                            color: root.ink
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: Compatibility.validPe && Compatibility.wineArchitecture
                            text: root.tr("A successful launch does not guarantee that the app, installer, or games will work.",
                                          "Pornirea nu garantează că aplicația, instalatorul sau jocul va funcționa.")
                            color: root.muted
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        CheckBox {
                            text: root.tr("Use a separate Wine environment for this app", "Folosește un mediu Wine separat pentru această aplicație")
                            checked: Compatibility.isolatedPrefix
                            enabled: Compatibility.canAttempt
                            onToggled: Compatibility.isolatedPrefix = checked
                        }
                        Text {
                            Layout.fillWidth: true
                            text: Compatibility.isolatedPrefix
                                ? root.tr("Recommended: keeps this app's Wine settings separate.", "Recomandat: păstrează separat setările Wine ale aplicației.")
                                : root.tr("Uses your shared default Wine environment (~/.wine).", "Folosește mediul Wine comun (~/.wine).")
                            color: root.muted
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: nativeColumn.implicitHeight + 28
                    radius: 14
                    color: "#151923"
                    border.color: "#2a3243"
                    ColumnLayout {
                        id: nativeColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 5
                        Text { text: root.tr("NATIVE LINUX VERSION", "VERSIUNE LINUX NATIVĂ"); color: root.violet; font.pixelSize: 11; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: Compatibility.nativeName.length > 0
                                ? root.tr("Possible match: " + Compatibility.nativeName + " has an official Linux version.",
                                          "Potrivire posibilă: " + Compatibility.nativeName + " are o versiune Linux oficială.")
                                : root.tr("No native version was identified from this file offline.",
                                          "Nu am identificat offline o versiune Linux nativă pentru acest fișier.")
                            color: root.ink
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: Compatibility.nativeName.length > 0
                            text: root.tr("Matched the file's embedded ProductName, which is not proof of publisher. Verify before downloading.",
                                          "Potrivire după ProductName din fișier; aceasta nu dovedește editorul. Verifică înainte de descărcare.")
                            color: root.muted
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: Compatibility.nativeName.length > 0
                            text: Compatibility.nativeUrl
                            color: root.blue
                            font.pixelSize: 12
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.tr("Only run software you trust. Wine programs run as your user and can access your files.",
                          "Rulează doar programe de încredere. Wine rulează cu drepturile contului tău și poate accesa fișierele tale.")
            color: "#ffc87a"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            visible: Compatibility.launchStatus.length > 0
            text: root.launchText()
            color: Compatibility.launchStatus === "started" ? root.blue : "#ff8f91"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Button {
                id: closeButton
                text: root.tr("Close", "Închide")
                focus: true
                onClicked: root.close()
            }
            Item { Layout.fillWidth: true }
            Button {
                visible: Compatibility.nativeName.length > 0
                text: root.tr("Official Linux page", "Pagina Linux oficială")
                onClicked: Compatibility.openNativePage()
            }
            Button {
                text: root.tr("Run with Wine", "Rulează cu Wine")
                enabled: Compatibility.canAttempt && Compatibility.launchStatus.length === 0
                onClicked: Compatibility.launchWithWine()
                contentItem: Text {
                    text: parent.text
                    color: "#0b0d14"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 9
                    color: parent.enabled ? (parent.down ? "#35addf" : root.blue) : "#51606a"
                    border.color: parent.activeFocus ? root.ink : "transparent"
                    border.width: parent.activeFocus ? 2 : 0
                }
            }
        }
    }
}
