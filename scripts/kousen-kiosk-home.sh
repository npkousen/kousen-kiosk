#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/kousen-kiosk/config.env"
KIOSK_URL="${KIOSK_URL:-https://kousen.cc}"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

LOG_DIR="${HOME}/.local/share/kousen-kiosk"
LOG_FILE="${LOG_DIR}/home-key.log"
mkdir -p "$LOG_DIR"

{
  echo "=== $(date -Is) returning home ==="
  echo "Kiosk URL: $KIOSK_URL"
} >> "$LOG_FILE"

if ! command -v xdotool >/dev/null 2>&1; then
  echo "xdotool is not installed" >> "$LOG_FILE"
  exit 1
fi

window_id="$(
  xdotool search --onlyvisible --class chromium 2>/dev/null | head -n 1 || true
)"

if [[ -z "$window_id" ]]; then
  window_id="$(
    xdotool search --onlyvisible --class google-chrome 2>/dev/null | head -n 1 || true
  )"
fi

if [[ -n "$window_id" ]]; then
  xdotool windowactivate --sync "$window_id" || true
fi

xdotool key --clearmodifiers ctrl+l
xdotool type --clearmodifiers "$KIOSK_URL"
xdotool key --clearmodifiers Return
