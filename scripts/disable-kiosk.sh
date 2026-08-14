#!/usr/bin/env bash
set -euo pipefail

KIOSK_USER="${KIOSK_USER:-kiosk}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo ./scripts/disable-kiosk.sh" >&2
  exit 1
fi

systemctl revert getty@tty1.service
rm -f /etc/kousen-kiosk/enabled

for tty in 2 3 4 5 6; do
  systemctl unmask "getty@tty${tty}.service" >/dev/null 2>&1 || true
done

rm -f "/home/${KIOSK_USER}/.bash_profile"

systemctl daemon-reload

echo "Kiosk auto-login disabled."
echo "Reboot to return to a normal login prompt: sudo reboot"
