# Real screenshot provenance

The 0.2 files below are unchanged captures from the original development project's
`artifacts/screenshots/`. They show the running NOVA Qt application; they are not
generated mockups or proof of installation. No private user desktop is visible.
The performance screenshot includes a development host CPU model and momentary
utilization. The update screenshot reports bootc unavailable in its environment;
the driver screenshot reports a virtual bochs-drm GPU. Keep those limits visible.

| File | SHA-256 |
| --- | --- |
| `performance-0.2.png` | `c02f1f878e2e4d8d960e4e97b11269d7402bd41c1a7517ac073f47b9ba9d495d` |
| `updates-0.2.png` | `7adee8f2e0ea1d8caf8f2fb9068f0a22ab3c6872c8a5dcf4c17296a5335cee98` |
| `drivers-0.2.png` | `bea47cbb4d2fa3a38dcf75f52e367cc5b67dbfb08ae23224da13d8390cce9250` |

NOVA original graphics and these application captures are licensed under MIT.
These screenshots contain no Opera window, third-party game art or personal photo.

## 0.3 native captures — 2026-10-22

The new captures show the actual requested 0.3 source implementation:

- `start-0.3.png`: the real NOVA Start applet in `plasmawindowed`, from the local
  0.3 runtime image, on an isolated 1280×720 X11 virtual display. The PNG captures
  the applet window itself at 580×520. Romanian translations are active. A
  separate keyboard test searched NOVA Update and launched its real application.
  This does not demonstrate the centered panel in a full Wayland session.
- `tasks-0.3.png` and `thispc-0.3.png`: the native compiled Control Center on
  the Fedora development VM, 1920×1080, offscreen/software Qt Quick, using an
  isolated preference file and `--no-desktop-integration`. Data is real VM
  process/memory/storage data; absent standard folders remain visibly absent.
  The full OS was not booted for these application captures.

| File | SHA-256 |
| --- | --- |
| `start-0.3.png` | `4e7061ba11be027ca88f535a1068ec2b651aad44dfc47dcaa7945ec17ac568ee` |
| `tasks-0.3.png` | `d3cb7175387b15df46d6afa9582b8f0c575a1ccd45c8ad2b2d5362835c4a5658` |
| `thispc-0.3.png` | `e726a0d5ef9dc83aec5daeb2ed77c8c881bf20586b4345b55fcd64549b0dd9a2` |

The captures are original NOVA UI documentation under MIT. Dependencies' names,
icons and other third-party materials retain upstream rights and notices.
