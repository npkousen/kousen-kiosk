# Recovery

## Exit The Kiosk Locally

Attach a keyboard and try:

```text
Ctrl+Alt+Backspace
```

If that does not work, switch to another TTY:

```text
Ctrl+Alt+F2
```

The installer masks tty2 through tty6 for kiosk hardening, so this may not be available unless you unmask a TTY first.

## SSH Recovery

SSH into the admin account:

```sh
ssh <admin-user>@<kiosk-ip>
```

Stop the kiosk auto-login:

```sh
sudo systemctl revert getty@tty1.service
sudo systemctl unmask getty@tty2.service getty@tty3.service getty@tty4.service getty@tty5.service getty@tty6.service
sudo rm -f /etc/kousen-kiosk/enabled
sudo reboot
```

## Change The Kiosk URL

Edit:

```text
/etc/kousen-kiosk/config.env
```

Set:

```sh
KIOSK_URL="https://kousen.cc"
```

Then reboot:

```sh
sudo reboot
```

## Re-run The Installer

From the repo:

```sh
sudo ./scripts/install.sh
sudo reboot
```

## Remove Kiosk Behavior

This keeps installed packages but removes the auto-login behavior.

From the repo:

```sh
sudo ./scripts/disable-kiosk.sh
sudo reboot
```

Manual equivalent:

```sh
sudo systemctl revert getty@tty1.service
sudo systemctl unmask getty@tty2.service getty@tty3.service getty@tty4.service getty@tty5.service getty@tty6.service
sudo rm -f /etc/kousen-kiosk/enabled
sudo rm -f /home/kiosk/.bash_profile
sudo reboot
```

## Logs

Useful commands:

```sh
journalctl -b
journalctl -u getty@tty1.service -b
cat /home/kiosk/.local/share/kousen-kiosk/startx.log
cat /home/kiosk/.local/share/kousen-kiosk/browser.log
cat /home/kiosk/.local/share/xorg/Xorg.0.log
```

## Show The GRUB Menu Again

The installer hides the GRUB boot menu for a cleaner kiosk startup.

To temporarily reach firmware settings, use the GMKtec boot keys during power-on:

```text
Esc - BIOS/UEFI setup
F7  - boot device menu
```

To permanently show GRUB again:

```sh
sudo rm -f /etc/default/grub.d/kousen-kiosk.cfg
sudo update-grub
sudo reboot
```
