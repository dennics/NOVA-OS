# NOVA OS 0.3 Preview — desktop and update implementation

Publication update, 2026-10-23: the moving Preview channel now provides
`0.3.1-preview`, with the Steam/Opera GX store repair and observed installed-VM
deployment/cold-boot/rollback evidence. Read [the current update report](UPDATE-0.3.1.md).
The paragraphs below preserve the original 0.3 implementation/test scope.

This is an experimental source implementation, not a published stable release.
The previous installer acceptance limits remain in effect. No physical HP update,
new ISO installation or working public 0.3 registry channel is claimed by this file.

## System updates

New installations track `ghcr.io/dennics/nova-os:preview`, a moving Preview
channel. Release images also receive individual `0.x.y-preview` tags. Updating
that channel is what makes a new OS version discoverable without reinstalling.
Publishing a new version under only its numbered tag is insufficient.

Settings → Updates provides a single **Download & install** action, streamed
operation details, installed/available/staged/previous versions, explicit restart
confirmation and rollback confirmation. The interface distinguishes a downloaded
image from an unlocked deployment that is ready for restart. bootc owns deployment
and recovery; NOVA does not replace its safety checks. User home files are outside
the OS image; application configuration compatibility still needs validation.

The `nova-update-check.timer` starts after boot and checks metadata every six
hours, with a randomized delay. It does not download full images, stage updates
or reboot. Checks and manual operations share an exclusive lock. Installation
requires administrative authentication and at least 8 GiB free on system storage;
this is a minimum preflight, not a prediction of every image's required space.

Legacy numbered NOVA Preview sources can be migrated from the 0.3 Settings page
to the fixed, allowlisted official Preview reference. Custom distributions and
registries are not silently switched. Existing 0.2 installations cannot gain new
UI before their first update: after public channel validation, the one-time
bootstrap is `pkexec bootc switch ghcr.io/dennics/nova-os:preview`, followed by
a restart. Do not run this while the channel is private or unpublished.

`scripts/publish-update.sh` refuses existing numbered tags and inconclusive
registry access, checks the image version label, uploads the numbered image,
requires anonymous readability, and then promotes the exact digest to `preview`.
A failed private-package check must not promote the channel. Invoke only after
native tests, image checks and deployment/rollback acceptance for the release.
Metadata/API use follows [bootc's documented interface](https://bootc.dev/bootc/bootc-api.7.html).

## Workspace

- **This PC** shows standard XDG personal folders and actual mounted storage,
  free space, filesystem and read-only status. It opens verified existing paths in
  Dolphin, does not move user files and does not mount or format devices.
- **Task Manager** shows `/proc` processes with CPU share of total machine
  capacity and resident memory in MiB. Sampling runs every two seconds only while
  visible. CPU/RAM overview sampling runs once per second. Hidden/minimized pages
  stop sampling. Search and sorting are local.
- Ending a process requires confirmation and is limited to the current user's
  processes. PID/start-time verification plus Linux pidfds prevents sending the
  signal to a replacement process after PID reuse. Only SIGTERM is offered.
- **NOVA Start** is an original Plasma applet with a searchable application grid,
  pinned desktop entries, This PC, Task Manager, Updates and KDE session actions.
  It uses KDE's existing application launch/search models. The default floating
  panel is centered and fits its contents. Keyboard search, Tab and Escape are
  supported. The panel migration replaces only the old explicitly NOVA-branded
  Kickoff widget and keeps other widgets and user pins.

The private Kicker QML API is tied to the tested Fedora/KDE version; validate the
applet after Plasma upgrades. Layout integration uses the documented
[Plasma scripting API](https://develop.kde.org/docs/plasma/scripting/api/).

## Boot and sound

Plymouth keeps the native `two-step` plugin, original frame count/timing,
boot progress, firmware/update messages and encrypted-disk password UI. The NOVA
generator replaces only the looping throbber art with two orbiting particle
trails around the original NOVA mark. It does not add a boot delay or invent a
progress percentage. Native text fallback remains available.

NOVA Orbit contains 14 original, deterministic stereo cues synthesized from
the MIT-licensed generator, without third-party audio recordings. The sound theme
inherits missing events from Ocean/freedesktop. System defaults select it for new
accounts; existing user sound preferences take priority. Personalization provides
preview buttons, **Use NOVA Orbit sounds**, and KDE sound-theme settings. Global
volume and notification sound preferences remain in KDE Settings.

## Validation required before release

The local native build, image lint, seven CTest suites, real Start keyboard
search/launch and visual captures have now run. Read the precise
[observed results and remaining acceptance work](VALIDATION-0.3.md).

Build with the pinned sources described in [BUILD.md](BUILD.md), then run the full
native CTest suite. `update-state-and-process-safety` covers status parsing,
legacy-source recognition, unavailable process data, sampling lifetime and
PID-safe termination of a deliberately spawned test child. The UI test loads all
eight pages, exercises keyboard navigation and checks monitor lifetime.

Release acceptance additionally needs a real Plasma session for the Start menu,
native captures at 1280×720/1920×1080, sound playback, boot/LUKS fallback, and an
actual 0.2.1 → 0.3 update/reboot/rollback with personal-file markers. Unit tests do
not establish those outcomes. Public GHCR visibility is still an external
publication prerequisite.
