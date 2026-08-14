#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/kousen-kiosk/config.env"
KIOSK_URL="${KIOSK_URL:-https://kousen.cc}"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

find_chromium() {
  local candidate
  for candidate in chromium chromium-browser google-chrome google-chrome-stable; do
    if command -v "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

CHROMIUM_BIN="$(find_chromium)"

xset s off || true
xset s noblank || true
xset -dpms || true

if command -v unclutter >/dev/null 2>&1; then
  unclutter -idle 0.5 -root >/dev/null 2>&1 &
fi

if command -v nm-online >/dev/null 2>&1; then
  nm-online --quiet --timeout=20 || true
fi

exec "$CHROMIUM_BIN" \
  --kiosk "$KIOSK_URL" \
  --user-data-dir="$HOME/.config/kousen-kiosk/chromium" \
  --no-first-run \
  --no-default-browser-check \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-features=Translate,AutofillServerCommunication \
  --overscroll-history-navigation=0 \
  --disable-pinch \
  --check-for-update-interval=31536000
