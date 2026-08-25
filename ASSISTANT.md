# Assistant Notes

This repository is the appliance layer for Kousen CommandCenter. Keep application changes in the `commandcenter` repo and device/OS provisioning changes here.

Operating assumptions:

- Primary kiosk URL is `https://kousen.cc`.
- The kiosk device is an x86_64 Linux mini PC.
- Prefer Debian minimal for first deployment.
- Do not add a full desktop environment unless explicitly requested.
- Keep the `kiosk` account unprivileged.
- Keep all secrets, WiFi passwords, SSH keys, and private LAN notes out of git.

When changing scripts, validate with:

```sh
bash -n scripts/*.sh
```

Recent field notes:

- `kousen-remote find --seconds 30` is the preferred Apple Siri Remote discovery path. It should identify candidates by Apple manufacturer data `0x004c`, HID service `00001812-0000-1000-8000-00805f9b34fb`, and appearance `0x03c0`; do not depend on a friendly Bluetooth name.
- A pre-pairing Siri Remote may score `85` and still report `Not yet observed: modalias bluetooth:v004Cp0315d0001`. That is acceptable before pairing.
- If `kousen-remote pair` waits without useful output, use `bluetoothctl` directly to pair/trust/connect, then rerun `sudo ./scripts/install.sh --include-remote --remote-device <address>`.
- USB-C display audio on MeLE hardware appeared as ALSA HDMI audio. If PipeWire exposes only analog, `kousen-kiosk-audio` should switch to an available HDMI/Digital card profile before selecting the sink.
- Current audio priority is display audio first, then built-in analog, then first available sink. A future tablet/headphone mode may need 3.5 mm jack detection so plugged-in headphones override speakers/display audio.
