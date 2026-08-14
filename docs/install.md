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

The installer will:

- install Chromium, Xorg, xinit, unclutter, and NetworkManager
- create the `kiosk` user if needed
- install the browser launcher
- install Chromium managed policies
- configure tty1 auto-login for the `kiosk` user
- disable extra local getty prompts on tty2 through tty6
- disable screen blanking in the kiosk session

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

## Updating CommandCenter Cards

Shared app cards are not managed by this repo. Update them in the CommandCenter repo by editing `apps.json`, committing, and pushing to `main`.
