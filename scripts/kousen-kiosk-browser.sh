#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/kousen-kiosk/config.env"
KIOSK_URL="${KIOSK_URL:-https://kousen.cc}"
LOG_DIR="$HOME/.local/share/kousen-kiosk"
LOG_FILE="$LOG_DIR/browser.log"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export CHROME_CRASHPAD_PIPE_NAME=""

mkdir -p \
  "$LOG_DIR" \
  "$XDG_CONFIG_HOME/kousen-kiosk/chromium" \
  "$XDG_CACHE_HOME/kousen-kiosk" \
  "$XDG_DATA_HOME/applications"
exec >> "$LOG_FILE" 2>&1

echo "=== $(date -Is) starting kousen kiosk browser ==="
echo "HOME: $HOME"
echo "XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
echo "XDG_CACHE_HOME: $XDG_CACHE_HOME"
echo "XDG_DATA_HOME: $XDG_DATA_HOME"

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
echo "Chromium binary: $CHROMIUM_BIN"
echo "Kiosk URL: $KIOSK_URL"

xset s off || true
xset s noblank || true
xset -dpms || true

if command -v unclutter >/dev/null 2>&1; then
  unclutter -idle 0.5 -root >/dev/null 2>&1 &
fi

if command -v nm-online >/dev/null 2>&1; then
  nm-online --quiet --timeout=20 || true
fi

exec dbus-run-session "$CHROMIUM_BIN" \
  --kiosk "$KIOSK_URL" \
  --user-data-dir="$HOME/.config/kousen-kiosk/chromium" \
  --no-first-run \
  --no-default-browser-check \
  --noerrdialogs \
  --disable-infobars \
  --disable-breakpad \
  --disable-crash-reporter \
  --disable-session-crashed-bubble \
  --disable-features=Translate,AutofillServerCommunication \
  --overscroll-history-navigation=0 \
  --disable-pinch \
  --check-for-update-interval=31536000
