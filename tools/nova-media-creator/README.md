# NOVA Media Creation Tool 0.3 Preview

The Windows frontend checks the NOVA ISO against its pinned byte length and
SHA-256, lists only identified USB disks that pass the system and state checks,
asks before erasing the selected stick, and reports the Fedora helper's write
and media-check stages. It invokes the pinned Fedora helper using its required
`write <ISO> <disk number>` command. If writing is interrupted, the stick may
be incomplete.

The unchanged Fedora Media Writer 5.3.2 portable package is embedded in the
single NOVA executable and verified against SHA-256
`1043a01b5bfc4b0a79b4f431696eeaeb18c605f38579009877aada3a836904da`. Its helper
is extracted to an administrator-owned, protected ProgramData cache and checked
again against its pinned hash before use. The helper is Fedora Media Writer
software, not NOVA code.

The cache audit checks write-capable permission bits, so a standard
`Users:ReadAndExecute` rule does not trigger a false failure through the broader
`Modify` mask. If a preflight check fails before the helper starts, the window
reports that the USB was not modified. It warns about incomplete media only
after the helper reports that raw writing began.

Fedora Media Writer and its helper are distributed under GPL-2.0-or-later and
Qt components retain their LGPL notices. The portable package contains the
upstream license notices. Corresponding source for the exact helper version is
available at [FedoraQt/MediaWriter 5.3.2](https://github.com/FedoraQt/MediaWriter/tree/5.3.2).
The frontend source and build script are included here. This local preview is
not digitally signed; Windows may show its normal publisher prompt.

Build on Windows with Windows PowerShell and the .NET Framework 4.8 compiler:

```powershell
.\build.ps1
```

The build checks the upstream archive and full NOVA ISO hashes before compiling.
`NOVA Media Creation Tool.release.json` and the adjacent `.sha256` file record
the generated executable hashes and release identity. The generated
`NOVA Media Creation Tool Preview QA.exe` is a safe UI preview: it uses a simulated
USB entry and cannot invoke the writing helper. Use the un-suffixed executable
for creating a real USB installer.
