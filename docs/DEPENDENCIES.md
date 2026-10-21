# External inputs

Cloning or auditing this repository downloads no binary dependencies. Exact
identities below come from the original project, not invented replacements.

| Input | Origin | Pinned SHA-256 |
| --- | --- | --- |
| Opera GX 137.0.6036.65 x86_64 RPM | `https://get.opera.com/pub/opera_gx/137.0.6036.65/linux/opera-gx-stable_137.0.6036.65_amd64.rpm` | `b911fb526d872e59ca8a3bf92e6e77fcf16a42a042b53f23f5abf97f74ebfd52` |
| Fedora Media Writer 5.3.2 portable ZIP | `https://github.com/FedoraQt/MediaWriter/releases/download/5.3.2/FedoraMediaWriter-win64-portable-5.3.2.zip` | `1043a01b5bfc4b0a79b4f431696eeaeb18c605f38579009877aada3a836904da` |

`scripts/fetch-dependency.py` retrieves only a named input on explicit request,
checks its hash before placing it in its ignored location, and does not run it.
Use `--accept-opera-eula` only after reviewing Opera's terms. It also retrieves
the official EULA page; that web page is mutable and is not a byte-identical
reconstruction of the originally downloaded HTML. The historical HTML hash was
`5e718fb28a0fd04f806d66d40753f06679412c91603d8260c192fb0ea233e76f`.

```sh
python3 scripts/fetch-dependency.py media-writer
# Only for authorized local Opera use after reading its EULA:
python3 scripts/fetch-dependency.py opera-gx --accept-opera-eula
```

Neither command grants public redistribution permission. Public Opera ISO/kit
distribution is not approved. The source commit contains neither payload.

Fedora/Image Builder OCI digests and private-bootstrap IDs are in
`sources.lock.json`. The latter require the original builder image store and are
not reconstructible from IDs alone. Fedora RPM repositories are not frozen;
see `BUILD.md` for the resulting reproducibility limitation.

Native development packages: CMake, Ninja, GCC C++20, Qt Core/Gui/Quick/
QuickControls2/DBus/Svg/Test, KF6 Config/Kirigami/IconThemes and Breeze icons.
Image tooling additionally uses Podman, skopeo, jq, Python, dracut, Anaconda,
slitherer, SELinux tooling and the dependencies recorded by configuration scripts.
