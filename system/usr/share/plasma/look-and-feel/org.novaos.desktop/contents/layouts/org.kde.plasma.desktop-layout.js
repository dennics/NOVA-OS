// SPDX-License-Identifier: MIT
var panel = new Panel;
panel.location = "bottom";
panel.height = 56;
panel.floating = true;
panel.alignment = "center";
panel.lengthMode = "fit";

var start = panel.addWidget("org.novaos.launcher");
start.globalShortcut = "Alt+F1";

var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.novaos.ControlCenter.desktop",
    "applications:org.novaos.ThisPC.desktop",
    "applications:opera-gx.desktop",
    "applications:org.kde.discover.desktop"
]);

panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
var clock = panel.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
panel.addWidget("org.kde.plasma.showdesktop");

var allDesktops = desktops();
for (var index = 0; index < allDesktops.length; ++index) {
    var desktop = allDesktops[index];
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", "file:///usr/share/wallpapers/NovaDark/contents/images/3840x2160.png");
}

