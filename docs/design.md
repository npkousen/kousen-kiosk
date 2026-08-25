# Kiosk Design

## Goal

Make the mini PC behave like a single-purpose appliance:

```text
boot -> open CommandCenter -> recover if the browser exits
```

The user should not land in a desktop, application menu, terminal, or file manager.

## Boot Model

The first implementation uses:

- systemd `getty@tty1` auto-login
- an unprivileged `kiosk` user
- `.bash_profile` on tty1
- `startx`
- Openbox as a tiny window manager
- Chromium in kiosk mode

This is deliberately plain. It avoids a full desktop environment while staying easy to debug from a local keyboard or SSH.

## Users

`kiosk`

- auto-login on tty1
- no sudo access
- starts the browser
- owns the browser profile

Admin user

- created during Linux install
- keeps sudo access
- used for maintenance, updates, and WiFi setup

## Browser

Chromium launches with:

- kiosk mode
- no first-run prompts
- no default-browser checks
- no session-crashed bubble
- no infobars
- no password storage prompts
- disabled restore prompts

The systemd getty restarts the session if the browser exits.

## Universal Home Key

Openbox binds a small set of keyboard/media keys to:

```sh
/usr/local/bin/kousen-kiosk-home
```

That script first uses Chromium's localhost debugging API to open `KIOSK_URL` in a fresh tab and close old page tabs. If that API is unavailable, it falls back to `xdotool` address-bar navigation.

Default bindings:

- `Home`
- `XF86HomePage`
- `Ctrl+Alt+Home`
- `Super+Home`
- `F12`

If a physical remote sends a different key symbol, add another `<keybind>` entry to `openbox/rc.xml`.

## Optional Remote Service

`kousen-remote` is intentionally optional because a fresh kiosk may not have a remote paired yet.

The kiosk installer supports:

```sh
sudo ./scripts/install.sh --include-remote
```

That clones the public `npkousen/kousen-remote` repo, installs its CLI and dependencies, and enables Bluetooth. It does not create the runtime service until the paired remote address is known.

After pairing a compatible remote:

```sh
sudo ./scripts/install.sh --include-remote --remote-device XX:XX:XX:XX:XX:XX
```

The service is managed separately as `kousen-remote.service` and emits normal Linux input events through the mapping in `kousen-remote`.

### Siri Remote Discovery

Do not rely on a friendly Bluetooth name when finding Apple Siri Remotes. During MeLE setup, macOS identified the remote only after pairing and showed an anonymous-looking name such as:

```text
C08RW4LJ2330
```

On Debian/BlueZ, the reliable pre-pairing signal came from Bluetooth metadata:

```text
ManufacturerData.Key: 0x004c
UUID: Human Interface Device (00001812-0000-1000-8000-00805f9b34fb)
Appearance: 0x03c0
```

`kousen-remote find` is the preferred discovery path because it performs a BLE HID-focused scan and scores devices against the bundled Siri Remote profile. A strong pre-pairing candidate may still lack `modalias bluetooth:v004Cp0315d0001`; that is acceptable before pairing.

If `kousen-remote pair` waits silently or BlueZ behaves differently on a new mini PC, use `bluetoothctl` directly for pairing so prompts and errors are visible. After pairing succeeds, rerun the kiosk installer with `--remote-device` so the systemd service is configured.

## Network

NetworkManager manages Ethernet and WiFi. The current repo includes an admin-run WiFi helper:

```sh
sudo kousen-configure-wifi
```

A future first-boot web WiFi portal can be added later if needed. Keep that portal local-only and backed by a narrow privileged helper instead of giving the kiosk browser general system privileges.

## Audio

Chromium audio uses PipeWire/WirePlumber on the kiosk session. The installer also includes ALSA tools for hardware-level inspection.

On each kiosk boot, `kousen-kiosk-audio` selects an output with this priority:

```text
HDMI / USB-C display audio -> built-in analog -> first available sink
```

USB-C DisplayPort audio is usually exposed by Linux as HDMI audio. Some devices expose the HDMI playback device through ALSA before PipeWire creates an HDMI sink. The kiosk audio helper therefore inspects available PipeWire card profiles and switches to an available HDMI/Digital profile before choosing the default sink.

If HDMI or USB-C display audio is connected but silent, inspect sinks with:

```sh
kousen-configure-audio
```

Then set the HDMI sink as default with:

```sh
sudo kousen-configure-audio set-default <sink-id>
```

Future consideration: tablet-style deployments may need headphone jack override behavior. The current kiosk preference is display audio first, which is appropriate for TV/monitor kiosks. If KousenTV is used on a tablet-like device with built-in speakers, a plugged-in 3.5 mm jack should probably override display/built-in speakers. Implementing that requires jack/port detection and a separate priority mode, for example:

```text
headphones if plugged in -> HDMI / USB-C display audio -> built-in speakers -> first available sink
```

## Why Not A Full Desktop

A normal desktop makes it easier to escape the kiosk and creates update prompts, app launchers, notifications, and settings surfaces that are not needed for this appliance.

## Why Not A Custom OS Image Yet

The first milestone should prove the device works reliably:

1. storage compatibility
2. display output
3. WiFi/Ethernet
4. Chromium hardware acceleration
5. reboot recovery

After that works on the GMKtec NucBox 7, image automation can be added.
