import QtQuick
import QtQuick.Window

// Original NOVA vectors; SVG rendering also works with the Qt Quick software backend.
Item {
    id: icon
    property string iconName: ""
    property color color: Theme.muted
    implicitWidth: 20
    implicitHeight: 20
    readonly property var paths: ({
        "view-dashboard": "M3 3h7v7H3z M14 3h7v7h-7z M3 14h7v7H3z M14 14h7v7h-7z",
        "preferences-desktop-theme-global": "M12 3a9 9 0 1 0 0 18h1a2 2 0 0 0 1-4 2 2 0 0 1 1-4h2a4 4 0 0 0 4-4c0-3-4-6-9-6z M7 9h.01 M11 6h.01 M16 7h.01 M6 13h.01",
        "utilities-system-monitor": "M4 20V12 M10 20V5 M16 20V9 M22 20H2",
        "computer": "M3 4h18v13H3z M8 21h8 M12 17v4 M6 7h12",
        "video-display": "M3 4h18v13H3z M8 21h8 M12 17v4 M8 8l-2 2 2 2 M16 8l2 2-2 2",
        "system-software-update": "M20 8a8 8 0 0 0-14-3L3 8 M3 3v5h5 M4 16a8 8 0 0 0 14 3l3-3 M21 21v-5h-5 M12 8v8 M9 13l3 3 3-3",
        "system-reboot": "M20 8a8 8 0 1 0 0 8 M20 3v5h-5 M12 8v5l3 2",
        "user-home": "M2 11l10-8 10 8 M5 10v11h14V10 M10 21v-7h4v7",
        "user-desktop": "M3 4h18v13H3z M8 21h8 M12 17v4",
        "folder-documents": "M3 6h7l2 3h9v12H3z M8 12h8 M8 16h6",
        "folder-downloads": "M3 6h7l2 3h9v12H3z M12 11v7 M9 15l3 3 3-3",
        "folder-pictures": "M3 6h7l2 3h9v12H3z M5 19l5-5 4 4 3-3 3 4 M16 12h.01",
        "folder-music": "M3 6h7l2 3h9v12H3z M11 18v-6l5-1v5 M8 18a1.5 1.5 0 1 0 3 0 M13 16a1.5 1.5 0 1 0 3 0",
        "folder-videos": "M3 6h7l2 3h9v12H3z M10 12l6 3-6 3z",
        "drive-harddisk": "M5 3h14l3 13v5H2v-5z M2 16h20 M16 19h.01 M19 19h.01",
        "drive-removable-media": "M7 3h10v18H7z M10 3v5h4V3 M10 18h4",
        "preferences-system": "M3 6h18 M3 12h18 M3 18h18 M8 3v6 M16 9v6 M10 15v6",
        "system-file-manager": "M3 6h7l2 3h9v11H3z M3 6V4h7l2 2",
        "applications-all": "M4 4h5v5H4z M15 4h5v5h-5z M4 15h5v5H4z M15 15h5v5h-5z",
        "view-refresh": "M20 8a8 8 0 1 0 0 8 M20 3v5h-5",
        "media-playback-start": "M8 4l13 8-13 8z",
        "go-next": "M3 12h18 M14 5l7 7-7 7",
        "preferences-desktop-display": "M3 4h18v13H3z M8 21h8 M12 17v4",
        "audio-volume-high": "M3 9h4l5-5v16l-5-5H3z M16 8a6 6 0 0 1 0 8 M19 5a10 10 0 0 1 0 14",
        "network-wireless": "M2 8a16 16 0 0 1 20 0 M5 12a11 11 0 0 1 14 0 M8 16a6 6 0 0 1 8 0 M12 20h.01",
        "preferences-system-bluetooth": "M7 6l11 12-6 4V2l6 4L7 18",
        "preferences-system-power-management": "M12 2v10 M6 5a9 9 0 1 0 12 0",
        "preferences-desktop-accessibility": "M12 3h.01 M3 8h18 M12 8v7 M7 22l5-7 5 7"
    })
    Image {
        anchors.fill: parent
        sourceSize.width: Math.max(20, icon.width * Screen.devicePixelRatio)
        sourceSize.height: Math.max(20, icon.height * Screen.devicePixelRatio)
        source: "data:image/svg+xml," + encodeURIComponent(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><path fill='none' stroke='"
            + icon.color + "' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round' d='"
            + (icon.paths[icon.iconName] || icon.paths["preferences-system"]) + "'/></svg>")
    }
}
