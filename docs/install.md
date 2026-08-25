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

## 5. Pair A Siri Remote

After installing with `--include-remote`, reboot or keep the admin SSH session open and find the remote:

```sh
kousen-remote find --seconds 30
```

While the finder is running, hold the Apple Siri Remote close to the mini PC and hold:

```text
Back/Menu + Volume Up
```

for about 5 seconds.

The remote may not advertise a friendly name. A good pre-pairing result is based on Bluetooth metadata instead:

```text
Likely Siri Remote candidate: E0:C3:EA:A4:3E:05 score=85
Matched: Apple manufacturer data 0x004c; Bluetooth HID service 00001812-0000-1000-8000-00805f9b34fb; HID remote-control appearance 0x03c0
Not yet observed: modalias bluetooth:v004Cp0315d0001
```

The missing modalias is normal before pairing. Use the address printed by the finder:

```sh
kousen-remote pair E0:C3:EA:A4:3E:05
```

If `kousen-remote pair` waits too long or does not show enough detail, pair directly through BlueZ:

```sh
bluetoothctl
```

Then run:

```text
power on
agent on
default-agent
pairable on
pair E0:C3:EA:A4:3E:05
trust E0:C3:EA:A4:3E:05
connect E0:C3:EA:A4:3E:05
info E0:C3:EA:A4:3E:05
quit
```

After pairing, enable the remote service:

```sh
cd ~/kousen-kiosk
sudo ./scripts/install.sh --include-remote --remote-device E0:C3:EA:A4:3E:05
sudo systemctl status kousen-remote.service --no-pager
```

Then reboot and test the remote:

```sh
sudo reboot
```

If the remote does not appear, make sure it is not connected to a Mac or Apple TV. Forget it on the Mac, turn Mac Bluetooth off temporarily, or unplug the Apple TV, then retry pairing mode.

## 6. Reboot

```sh
sudo reboot
```

The device should boot directly into Chromium at:

```text
https://kousen.cc
```

## 7. Configure WiFi

From the admin account or SSH:

```sh
sudo kousen-configure-wifi
```

Then reboot or restart NetworkManager:

```sh
sudo systemctl restart NetworkManager
```

## Configure Audio

Kousen Kiosk uses PipeWire/WirePlumber for Chromium audio and ALSA tools for hardware inspection.

Inspect audio state:

```sh
sudo kousen-configure-audio
```

Run automatic output selection:

```sh
sudo kousen-configure-audio auto
```

For HDMI and USB-C displays, Linux commonly exposes display audio as an HDMI device. On MeLE-style hardware, ALSA may show the display output immediately:

```text
card 0: PCH [HDA Intel PCH], device 3: HDMI 0 [AirPanel 16]
```

while PipeWire initially exposes only analog:

```text
Sinks:
* Built-in Audio Analog Stereo
```

The kiosk audio helper handles this by selecting an available HDMI/Digital PipeWire card profile before choosing the sink. To verify manually:

```sh
sudo -u kiosk XDG_RUNTIME_DIR=/run/user/$(id -u kiosk) pw-cli enum-params <device-id> EnumProfile
```

Look for an available profile such as:

```text
output:hdmi-stereo
Digital Stereo (HDMI) Output
available: yes
```

Hardware-level test:

```sh
speaker-test -D plughw:0,3 -c 2 -t sine -f 440
```

Use the correct card/device from `aplay -l`.

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
