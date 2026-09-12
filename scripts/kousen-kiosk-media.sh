#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"

usage() {
  cat <<'EOF'
Usage: kousen-kiosk-media <play|pause|play-pause|home|button> [detail...]

Shows a kiosk OSD event. This is intended for kousen-remote side-channel
notifications for app-directed buttons that should still reach Chromium.
EOF
}

if [[ -z "$action" || "$action" == "-h" || "$action" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v kousen-kiosk-osd >/dev/null 2>&1; then
  exit 0
fi

case "$action" in
  play|pause|play-pause|home)
    kousen-kiosk-osd "$action" || true
    ;;
  button)
    shift
    kousen-kiosk-osd button "$@" || true
    ;;
  *)
    shift || true
    kousen-kiosk-osd button "$action" "$@" || true
    ;;
esac
