# Install Guide

## 1. Install Linux

Install Debian stable minimal or Ubuntu Server LTS on the mini PC.

During OS install:

- create a normal admin user
- enable SSH if you want remote maintenance
- do not install a desktop environment
- connect Ethernet if available

After first boot, log in as the admin user.

## 2. Install Git

```sh
sudo apt-get update
sudo apt-get install -y git ca-certificates
```

## 3. Clone This Repo

```sh
git clone https://github.com/npkousen/kousen-kiosk.git
cd kousen-kiosk
```

## 4. Run The Installer

```sh
sudo ./scripts/install.sh
```

Optional URL override:

```sh
sudo KIOSK_URL="https://kousen.cc" ./scripts/install.sh
```

Optional remote-control support:

```sh
sudo ./scripts/install.sh --include-remote
```

That installs the public `kousen-remote` package and its Bluetooth/Python dependencies without requiring GitHub credentials. It does not enable the `kousen-remote` systemd service until a paired remote device address is supplied:

```sh
sudo ./scripts/install.sh --include-remote --remote-device XX:XX:XX:XX:XX:XX
```

The installer will:

- install Chromium, Xorg, xinit, unclutter, and NetworkManager
- create the `kiosk` user if needed
- install the browser launcher
- install Chromium managed policies
- configure tty1 auto-login for the `kiosk` user
- leave tty2 through tty6 available for local recovery
- disable screen blanking in the kiosk session
- optionally install and configure `kousen-remote`

## 5. Reboot

```sh
sudo reboot
```

The device should boot directly into Chromium at:

```text
https://kousen.cc
```

## 6. Configure WiFi

From the admin account or SSH:

```sh
sudo kousen-configure-wifi
```

Then reboot or restart NetworkManager:

```sh
sudo systemctl restart NetworkManager
```

## Updating The Kiosk

Pull repo updates and rerun the installer:

```sh
cd kousen-kiosk
git pull
sudo ./scripts/install.sh
sudo reboot
```

If the kiosk uses `kousen-remote`, keep including it during updates:

```sh
sudo ./scripts/install.sh --include-remote
```

If the service is configured for a paired remote, include the device address:

```sh
sudo ./scripts/install.sh --include-remote --remote-device XX:XX:XX:XX:XX:XX
```

## Updating CommandCenter Cards

Shared app cards are not managed by this repo. Update them in the CommandCenter repo by editing `apps.json`, committing, and pushing to `main`.
