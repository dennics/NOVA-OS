# Steam and Opera GX first installation

## Reported on NOVA OS 0.3 Preview, 2026-10-23

The HP installation reported Discover's error:

```
No entry for appstream://com.valvesoftware.steam
```

The NOVA launcher passed `appstream://com.valvesoftware.Steam`. Qt normalizes
URL hostnames to lowercase; Discover reads that hostname as an AppStream ID.
Steam's actual Flathub ID is case-sensitive: `com.valvesoftware.Steam`.
AppStream discovery also requires available repository metadata. The screenshot
does not establish whether the HP had a configured Flathub remote, a downloaded
catalog or a working network connection.

The source fix opens an upstream `.flatpakref` as a local installation file in
Discover. It carries the exact ID, repository URL, public signing key and
runtime repository. This avoids the URL/cached-catalog dependency. Discover
still requires the user's installation confirmation and internet access to
download the application and runtime. Installed applications run directly from
their explicit user/system installation, preserving arguments.

## Repair an existing installation without reinstalling NOVA

The fix is published as NOVA OS `0.3.1-preview` on the public Preview channel.
In NOVA Settings → Updates, check for updates, choose Download & install and
restart when ready. Then open Steam and confirm installation in Discover.
The application/runtime download needs internet access and is separate from
the OS update. Older numbered or placeholder update sources need the Settings
page's Connect NOVA Preview action; a current 0.3 ISO installation already
tracks the moving channel. See [update validation](UPDATE-0.3.1.md).

For an application-only workaround without updating the system image:

Download the official Steam reference and open it with Discover:

https://dl.flathub.org/repo/appstream/com.valvesoftware.Steam.flatpakref

Alternatively, run as the normal desktop user, without `sudo`:

```sh
flatpak install --user --from https://dl.flathub.org/repo/appstream/com.valvesoftware.Steam.flatpakref
```

Review the repository/permission prompts and confirm installation. The existing
NOVA Steam icon can then start the installed application. Opera GX uses the
same method with `com.opera.opera-gx.flatpakref`. No system-image write, security
setting change or disk formatting is needed. The previously delivered 0.3 ISO
still has the old launcher; the OS update provides the corrected one.

## Evidence and limits

`tests/store_launcher_test.py` exercises first installation with no available
catalog, direct launches in both installation scopes, literal arguments and a
visible error for missing references. All six tests and Bash syntax validation
passed in the dedicated Fedora builder on 2026-10-23. The installed Qt 6.11.2
reproduced `Steam` becoming `steam` in the URL host. The original NOVA 0.3
runtime's Discover confirmed support for `--local-filename`; its Flatpak 1.18.4
successfully resolved `app/com.valvesoftware.Steam/x86_64/stable` from Flathub
in a temporary, empty user installation, with repository signature verification
enabled. No application or runtime was installed during that check.

These checks do not establish successful GUI installation, Steam startup or
game execution on the user's HP. A complete interactive GUI installation has
not been validated for this repair.

Upstream references:

- Qt URL handling: https://doc.qt.io/qt-6/qurl.html
- Flatpak installation: https://docs.flatpak.org/en/latest/using-flatpak.html
- Discover local files: https://invent.kde.org/plasma/discover/-/blob/master/discover/main.cpp
