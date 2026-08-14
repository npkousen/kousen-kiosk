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

if command -v python3 >/dev/null 2>&1; then
  if python3 - "$KIOSK_URL" >> "$LOG_FILE" 2>&1 <<'PY'
import json
import sys
import urllib.parse
import urllib.request

home_url = sys.argv[1]
base_url = "http://127.0.0.1:9222"

def request(path, method="GET"):
    req = urllib.request.Request(base_url + path, method=method)
    with urllib.request.urlopen(req, timeout=2) as response:
        return response.read().decode("utf-8", errors="replace")

tabs = json.loads(request("/json/list"))
old_page_ids = [tab["id"] for tab in tabs if tab.get("type") == "page" and "id" in tab]

new_tab = json.loads(request("/json/new?" + urllib.parse.quote(home_url, safe=""), method="PUT"))
new_tab_id = new_tab.get("id")

if new_tab_id:
    request("/json/activate/" + urllib.parse.quote(new_tab_id, safe=""))

for tab_id in old_page_ids:
    if tab_id != new_tab_id:
        try:
            request("/json/close/" + urllib.parse.quote(tab_id, safe=""))
        except Exception as exc:
            print(f"Could not close old tab {tab_id}: {exc}")

print("Navigated home through Chromium remote debugging API")
PY
  then
    exit 0
  fi
fi

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
