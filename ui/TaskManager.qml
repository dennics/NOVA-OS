import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 20
    property var cpuHistory: []
    property var memoryHistory: []
    property var selectedProcess: ({})
    Connections {
        target: Metrics
        function onSampleChanged() {
            if (Metrics.cpuValid) root.cpuHistory = root.cpuHistory.concat([Metrics.cpuPercent]).slice(-40)
            if (Metrics.memoryValid) root.memoryHistory = root.memoryHistory.concat([Metrics.memoryPercent]).slice(-40)
        }
    }
    Text { text: Theme.textFor("Task Manager", "Task Manager"); color: Theme.text; font.pixelSize: Theme.heading; font.weight: Font.DemiBold }
    Text { text: Theme.textFor("A live view of what's using your PC.", "Vezi în timp real ce folosește resursele calculatorului."); color: Theme.muted; font.pixelSize: Theme.body; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    RowLayout {
        Layout.fillWidth: true
        spacing: 16
        Repeater {
            model: [{title: "CPU", memory: false}, {title: Theme.textFor("Memory", "Memorie"), memory: true}]
            delegate: NovaCard {
                id: metricCard
                required property var modelData
                readonly property bool available: modelData.memory ? Metrics.memoryValid : Metrics.cpuValid
                readonly property real percent: modelData.memory ? Metrics.memoryPercent : Metrics.cpuPercent
                readonly property color tint: modelData.memory ? Theme.violet : Theme.accent
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: modelData.title; color: Theme.muted; font.pixelSize: Theme.body; Layout.fillWidth: true }
                    Text { text: metricCard.available ? metricCard.percent.toFixed(1) + "%" : "—"; color: metricCard.tint; font.pixelSize: 30; font.weight: Font.DemiBold }
                }
                Row {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    spacing: 3
                    Repeater {
                        model: modelData.memory ? root.memoryHistory : root.cpuHistory
                        delegate: Rectangle {
                            required property real modelData
                            width: Math.max(2, (parent.width - 117) / 40)
                            height: Math.max(3, modelData * 0.64)
                            y: 64 - height
                            radius: 2
                            color: modelData > 90 ? "#f2c078" : metricCard.tint
                            opacity: 0.8
                        }
                    }
                }
                Text { text: modelData.memory && Metrics.memoryValid ? Metrics.memoryUsedGiB.toFixed(1) + " / " + Metrics.memoryTotalGiB.toFixed(1) + " GiB" : Theme.textFor("Total CPU capacity", "Capacitate CPU totală"); color: Theme.muted; font.pixelSize: Theme.small }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        TextField { objectName: "process-search"; Layout.fillWidth: true; placeholderText: Theme.textFor("Search by name or PID", "Caută după nume sau PID"); text: Processes.query; onTextEdited: Processes.query = text; Accessible.name: placeholderText }
        ComboBox {
            model: [Theme.textFor("CPU usage", "Utilizare CPU"), Theme.textFor("Memory", "Memorie"), Theme.textFor("Name", "Nume")]
            Accessible.name: Theme.textFor("Sort processes", "Sortează procesele")
            onActivated: Processes.sortBy = ["cpu", "memory", "name"][currentIndex]
        }
    }
    Text { text: Processes.processCount + Theme.textFor(" processes · CPU is a share of all cores", " procese · CPU reprezintă proporția din toate nucleele"); color: Theme.muted; font.pixelSize: Theme.small; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 414
        color: Theme.surface
        radius: 16
        border.color: Theme.border
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Text { text: Theme.textFor("APPLICATION / PROCESS", "APLICAȚIE / PROCES"); color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1; Layout.fillWidth: true }
                Text { text: "CPU"; color: Theme.muted; font.pixelSize: 11; Layout.preferredWidth: 58 }
                Text { text: "RAM"; color: Theme.muted; font.pixelSize: 11; Layout.preferredWidth: 82 }
                Item { Layout.preferredWidth: 80 }
            }
            ListView {
                id: list
                objectName: "process-list"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: Processes.processes
                ScrollBar.vertical: ScrollBar {}
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width - 12
                    height: 56
                    radius: 10
                    color: index % 2 ? "#10141f" : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text { text: modelData.name; textFormat: Text.PlainText; color: Theme.text; font.pixelSize: Theme.body; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: "PID " + modelData.pid + " · " + modelData.state; color: Theme.muted; font.pixelSize: 10 }
                        }
                        Text { text: modelData.cpuValid ? modelData.cpu.toFixed(1) + "%" : "—"; color: Theme.accent; font.pixelSize: Theme.small; Layout.preferredWidth: 58 }
                        Text { text: modelData.memoryMiB.toFixed(1) + " MiB"; color: Theme.text; font.pixelSize: Theme.small; Layout.preferredWidth: 82 }
                        Button {
                            text: Theme.textFor("End", "Închide")
                            implicitWidth: 76
                            enabled: modelData.canEnd
                            opacity: enabled ? 1 : 0.35
                            Accessible.name: text + " " + modelData.name
                            onClicked: { root.selectedProcess = modelData; endDialog.open() }
                        }
                    }
                }
            }
        }
    }
    Text { visible: Processes.message !== ""; text: Processes.message; color: "#f2c078"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    Text { text: Theme.textFor("Updates every two seconds while visible. Ending a process can lose unsaved work. Only your own processes can be closed.", "Actualizare la două secunde cât pagina este vizibilă. Închiderea unui proces poate pierde lucrul nesalvat. Poți închide doar procesele contului tău."); color: Theme.muted; font.pixelSize: Theme.small; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    Dialog {
        id: endDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(440, parent.width - 40)
        title: Theme.textFor("End process?", "Închizi procesul?")
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: Label { text: root.selectedProcess.name + " (PID " + root.selectedProcess.pid + ")\n\n" + Theme.textFor("Unsaved work may be lost.", "Lucrul nesalvat se poate pierde."); wrapMode: Text.WordWrap }
        onAccepted: Processes.endProcess(root.selectedProcess.pid, root.selectedProcess.startTime)
    }
}
