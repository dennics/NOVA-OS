# NOVA OS 0.2.1 Preview update

This source change prepares a 0.2.1 Preview image to repair Wine launch
diagnostics, provide the signed Flathub source for Discover, add app launchers
for Opera GX and Steam, and configure a real bootc registry reference. The
proprietary browser and Steam binaries are not bundled; Discover installs them
from Flathub after the user chooses to do so. The image is not available to
existing laptops until it has been built, tested, and pushed to the public
registry.

The 0.2.0 installation currently points at `nova.invalid/nova:preview`. Its
Update Center therefore cannot discover a new image. After the 0.2.1 image is
published, an existing installation needs this one-time source migration from
a terminal:

```sh
pkexec bootc switch ghcr.io/dennics/nova-os:0.2.1-preview
```

The graphical polkit prompt authorizes the image switch. After bootc finishes,
restart into the staged deployment. Later image versions can then use the NOVA
Update Center. Do not run the command until the public image has been verified.

NOVA's Opera GX and Steam launchers open the exact Discover application page
when the app is not installed. Flathub provides Opera GX under the Opera name;
its official announcement lists Flathub as a Linux distribution channel.
Steam's Flathub package is community maintained and not officially supported
by Valve. Fedora's `steam-devices` package provides controller rules. This does
not guarantee that a particular game or anti-cheat system works.

Wine now reports whether its process started, its exit result, and the last
output in a log under `~/.local/share/nova-compatibility/wine-logs/`. This
distinguishes a Wine launch failure from an application compatibility failure;
it cannot make every Windows application compatible.

No 0.2.1 image or laptop update has passed validation until build and offline
update acceptance evidence is recorded. A 0.2.0 install still needs a one-time
source migration because its Update Center intentionally rejects the
`nova.invalid` placeholder.
