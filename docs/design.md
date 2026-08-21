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
HDMI -> built-in analog -> first available sink
```

If HDMI is connected but silent, inspect sinks with:

```sh
kousen-configure-audio
```

Then set the HDMI sink as default with:

```sh
sudo kousen-configure-audio set-default <sink-id>
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
