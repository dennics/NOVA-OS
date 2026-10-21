pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "#0b0d14"
    readonly property color surface: "#151923"
    readonly property color raised: "#1c2230"
    readonly property color border: "#2a3243"
    readonly property color text: "#f3f5fa"
    readonly property color muted: "#a4aec2"
    readonly property color accent: Preferences.accent
    readonly property color violet: "#9775ff"
    readonly property real fontScale: Math.max(1, Qt.application.font.pointSize / 10)
    readonly property int body: Math.round(14 * fontScale)
    readonly property int small: Math.round(12 * fontScale)
    readonly property int heading: Math.round(30 * fontScale)
    readonly property color onAccent: (0.2126 * linear(accent.r) + 0.7152 * linear(accent.g) + 0.0722 * linear(accent.b)) > 0.179 ? "#0b0d14" : "#ffffff"
    function linear(value) { return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4) }
    function textFor(english, romanian) { return Preferences.language === "ro" ? romanian : english }
}

