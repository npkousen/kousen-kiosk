# Kousen Kiosk

Kousen Kiosk turns a small Linux mini PC into a browser appliance for Kousen CommandCenter.

This repo also includes a public project homepage in `index.html`. It can be served directly by GitHub Pages from the repository root.

Target boot behavior:

```text
power on -> Linux boots -> kiosk user auto-login -> Chromium opens https://kousen.cc
```

The kiosk has no normal desktop, no launcher, and no sudo access for the kiosk user. Maintenance is done through a separate admin user or SSH.

## Target Hardware

Initial target:

- GMKtec NucBox 7
- Intel Pentium Silver N6005
- 16 GB RAM
- KingSpec 1 TB M.2 2242 SATA III SSD

The repo is intentionally generic enough for other x86_64 mini PCs.

## Recommended OS

Use a minimal server install:

- Debian stable minimal, recommended
- Ubuntu Server LTS, acceptable

Do not install GNOME, KDE, XFCE, or another desktop environment. This repo installs only the display pieces needed to run Chromium full screen.

## Quick Start

On a fresh Linux install:

```sh
git clone https://github.com/npkousen/kousen-kiosk.git
cd kousen-kiosk
sudo ./scripts/install.sh
sudo reboot
```

By default the kiosk opens:

```text
https://kousen.cc
```

Override the URL during install:

```sh
sudo KIOSK_URL="https://kousen.cc" ./scripts/install.sh
```

## WiFi

For first setup, use the admin account or SSH and run:

```sh
sudo kousen-configure-wifi
```

That command uses NetworkManager to scan for WiFi networks and save the selected connection.

After WiFi is saved, you can unplug Ethernet and reboot. The kiosk waits up to 60 seconds for NetworkManager before opening Chromium, which avoids most first-boot "no internet" pages.

## Universal Home Key

The kiosk includes a system-level home action that returns Chromium to:

```text
https://kousen.cc
```

Default keybindings:

- `Home`
- browser/media `Home` (`XF86HomePage`)
- `Ctrl+Alt+Home`
- `Super+Home`
- `F12`

These work from Plex, KousenTV, or any other current browser page because the shortcut is handled by Openbox outside the web app.

## Optional Kousen Remote

The installer can optionally include [`kousen-remote`](https://github.com/npkousen/kousen-remote), a standalone Linux service that turns a supported Bluetooth remote into normal keyboard/media input.

Install or refresh the remote CLI and dependencies:

```sh
sudo ./scripts/install.sh --include-remote
```

That does not enable the remote service yet because the service needs a paired remote device address. After pairing a remote, rerun with:

```sh
sudo ./scripts/install.sh --include-remote --remote-device XX:XX:XX:XX:XX:XX
```

To install and enable the service without starting it immediately:

```sh
sudo ./scripts/install.sh --include-remote --remote-device XX:XX:XX:XX:XX:XX --remote-no-start
```

## Audio

The installer adds PipeWire, WirePlumber, and ALSA tools so Chromium can output through HDMI, analog headphones, or USB audio.

On each kiosk boot, audio is selected automatically:

```text
HDMI -> built-in analog -> first available sink
```

To inspect audio outputs:

```sh
kousen-configure-audio
```

If HDMI is not selected automatically, use the HDMI sink id shown by `wpctl status`:

```sh
sudo kousen-configure-audio set-default <sink-id>
```

To rerun the automatic selector without rebooting:

```sh
sudo kousen-configure-audio auto
```

## Repo Layout

- `scripts/install.sh` - provisions the kiosk on a fresh Linux install
- `index.html` - public project homepage and detailed install walkthrough
- `scripts/kousen-kiosk-browser.sh` - Chromium kiosk launcher
- `scripts/configure-wifi.sh` - WiFi setup helper
- `scripts/configure-audio.sh` - audio output inspection helper
- `scripts/kousen-kiosk-home.sh` - universal return-home action
- `scripts/install-kousen-remote.sh` - optional kousen-remote installer
- `scripts/disable-kiosk.sh` - removes kiosk auto-login for recovery
- `openbox/rc.xml` - kiosk keyboard and remote shortcuts
- `systemd/getty@tty1.override.conf` - auto-login config for the kiosk user
- `chromium/policies/managed/kousen-kiosk.json` - managed Chromium restrictions
- `docs/install.md` - full install process
- `docs/hardware.md` - hardware notes
- `docs/recovery.md` - maintenance and rollback
- `docs/design.md` - architecture decisions

## CommandCenter Context

CommandCenter is hosted at `https://kousen.cc` through GitHub Pages. Its shared app cards are defined in that project's `apps.json`, currently including LAN links such as:

```text
KousenTV -> http://192.168.10.10:8000
Plex     -> http://192.168.10.10:32400/web
```

This repo does not host CommandCenter. It configures the mini PC that displays it.

## License

This project is open source under the MIT License. See `LICENSE` for details.
