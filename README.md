# Kousen Kiosk

Kousen Kiosk turns a small Linux mini PC into a browser appliance for Kousen CommandCenter.

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

## Repo Layout

- `scripts/install.sh` - provisions the kiosk on a fresh Linux install
- `scripts/kousen-kiosk-browser.sh` - Chromium kiosk launcher
- `scripts/configure-wifi.sh` - WiFi setup helper
- `scripts/disable-kiosk.sh` - removes kiosk auto-login for recovery
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
