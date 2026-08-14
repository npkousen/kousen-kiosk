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
