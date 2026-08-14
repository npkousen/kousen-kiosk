#!/usr/bin/env bash
set -euo pipefail

KIOSK_USER="${KIOSK_USER:-kiosk}"
KIOSK_URL="${KIOSK_URL:-https://kousen.cc}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo ./scripts/install.sh" >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer currently supports Debian/Ubuntu systems with apt-get." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update

CHROMIUM_PACKAGE=""
if apt-cache show chromium >/dev/null 2>&1; then
  CHROMIUM_PACKAGE="chromium"
elif apt-cache show chromium-browser >/dev/null 2>&1; then
  CHROMIUM_PACKAGE="chromium-browser"
else
  echo "Could not find a Chromium package in apt." >&2
  exit 1
fi

apt-get install -y \
  ca-certificates \
  "$CHROMIUM_PACKAGE" \
  dbus-x11 \
  network-manager \
  unclutter \
  x11-xserver-utils \
  xinit \
  xserver-xorg

systemctl enable NetworkManager

if ! id "$KIOSK_USER" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "$KIOSK_USER"
fi

install -d -m 0755 /etc/kousen-kiosk
cat > /etc/kousen-kiosk/config.env <<EOF
KIOSK_URL="${KIOSK_URL}"
EOF
touch /etc/kousen-kiosk/enabled

install -m 0755 "$REPO_DIR/scripts/kousen-kiosk-browser.sh" /usr/local/bin/kousen-kiosk-browser
install -m 0755 "$REPO_DIR/scripts/configure-wifi.sh" /usr/local/sbin/kousen-configure-wifi

install -d -m 0755 /etc/chromium/policies/managed
install -m 0644 "$REPO_DIR/chromium/policies/managed/kousen-kiosk.json" /etc/chromium/policies/managed/kousen-kiosk.json

install -d -m 0755 /etc/systemd/system/getty@tty1.service.d
install -m 0644 "$REPO_DIR/systemd/getty@tty1.override.conf" /etc/systemd/system/getty@tty1.service.d/override.conf

cat > "/home/${KIOSK_USER}/.bash_profile" <<'EOF'
if [[ -z "${DISPLAY:-}" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
  if [[ -f /etc/kousen-kiosk/enabled ]]; then
    mkdir -p "$HOME/.local/share/kousen-kiosk"
    while [[ -f /etc/kousen-kiosk/enabled ]]; do
      startx /usr/local/bin/kousen-kiosk-browser -- -nolisten tcp >> "$HOME/.local/share/kousen-kiosk/startx.log" 2>&1
      sleep 5
    done
  fi
fi
EOF

chown "$KIOSK_USER:$KIOSK_USER" "/home/${KIOSK_USER}/.bash_profile"
chmod 0644 "/home/${KIOSK_USER}/.bash_profile"

install -d -m 0700 -o "$KIOSK_USER" -g "$KIOSK_USER" "/home/${KIOSK_USER}/.config/kousen-kiosk"
install -d -m 0700 -o "$KIOSK_USER" -g "$KIOSK_USER" "/home/${KIOSK_USER}/.cache/kousen-kiosk"
install -d -m 0700 -o "$KIOSK_USER" -g "$KIOSK_USER" "/home/${KIOSK_USER}/.local/share/kousen-kiosk"
install -d -m 0700 -o "$KIOSK_USER" -g "$KIOSK_USER" "/home/${KIOSK_USER}/.local/share/applications"
chown -R "$KIOSK_USER:$KIOSK_USER" "/home/${KIOSK_USER}/.config" "/home/${KIOSK_USER}/.cache" "/home/${KIOSK_USER}/.local"

for tty in 2 3 4 5 6; do
  systemctl unmask "getty@tty${tty}.service" >/dev/null 2>&1 || true
done

systemctl daemon-reload
systemctl enable getty@tty1.service

echo "Kousen Kiosk installed."
echo "Kiosk user: ${KIOSK_USER}"
echo "Kiosk URL:  ${KIOSK_URL}"
echo "Reboot to enter kiosk mode: sudo reboot"
