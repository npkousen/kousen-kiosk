# Hardware Notes

## Initial Device

GMKtec NucBox 7:

- Intel Pentium Silver N6005
- 16 GB RAM
- M.2 2242 SATA storage slot

Planned SSD:

- KingSpec 1 TB M.2 2242 SATA III

The SSD should be compatible on paper because the device storage slot and SSD are both M.2 2242 SATA. Verify physically before relying on this for the final build.

## BIOS Settings

Recommended starting settings:

- Power on after AC restore: enabled, if available
- Full screen logo / boot logo / quiet boot: disable, if available
- Secure Boot: disabled for first Linux install if it causes boot friction
- Boot order: internal SSD first after install
- Fast Boot: disabled during setup, optional after stable
- Wake on LAN: optional

GMKtec firmware typically uses:

```text
Esc - BIOS/UEFI setup
F7  - boot device menu
```

The GMKtec splash/logo is controlled by firmware. If the BIOS has a setting named `Full Screen Logo`, `Boot Logo`, or `Quiet Boot`, disable it to reduce or remove the splash screen. Do not flash or modify firmware just to remove the logo.

## Display

Use HDMI for the first build. Confirm the kiosk boots correctly at the target TV or monitor resolution before locking the device away.

## USB-C

The NucBox 7 USB-C port should be treated as power input only. GMKtec's NucBox 7 manual labels the port as:

```text
Type-C DC IN ONLY
```

So USB-C DisplayPort Alt Mode / USB-C monitor video output should not be expected on this model. Use HDMI for video and HDMI audio.

Some USB-C monitors may be able to power the mini PC, but that does not mean the port can also carry video or USB data.

## Keyboard

Keep a USB keyboard available during setup and recovery. The final kiosk can run without one.

## Network

Ethernet is preferred for the first boot because it removes WiFi setup from the initial OS install. WiFi can be configured afterward with:

```sh
sudo kousen-configure-wifi
```
