// SPDX-License-Identifier: MIT
// Upgrade only the explicitly branded NOVA launcher; keep every other widget,
// user launcher, desktop icon, wallpaper and panel untouched.
if (knownWidgetTypes.includes("org.novaos.launcher")) {
    var existingPanels = panels();
    for (var p = 0; p < existingPanels.length; ++p) {
        var panel = existingPanels[p];
        var launchers = panel.widgets("org.kde.plasma.kickoff");
        for (var w = 0; w < launchers.length; ++w) {
            var old = launchers[w];
            old.currentConfigGroup = ["General"];
            if (old.readConfig("icon", "") !== "nova-control-center") continue;
            var position = old.index;
            var shortcut = old.globalShortcut;
            old.globalShortcut = "";
            var replacement = panel.addWidget("org.novaos.launcher");
            replacement.index = position;
            old.remove();
            replacement.globalShortcut = shortcut || "Alt+F1";
            panel.alignment = "center";
            panel.lengthMode = "fit";
            panel.floating = true;
            panel.height = Math.max(52, panel.height);
        }
    }
}
