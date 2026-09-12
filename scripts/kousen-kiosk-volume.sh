#!/usr/bin/env bash
set -euo pipefail

step="${KIOSK_VOLUME_STEP:-5%}"
action="${1:-}"

usage() {
  cat <<'EOF'
Usage: kousen-kiosk-volume <up|down|mute|toggle-mute>

Changes the default PipeWire sink volume and shows the kiosk OSD.
EOF
}

if [[ -z "$action" || "$action" == "-h" || "$action" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v wpctl >/dev/null 2>&1; then
  if command -v kousen-kiosk-osd >/dev/null 2>&1; then
    kousen-kiosk-osd event volume "Volume" "PipeWire unavailable" || true
  fi
  exit 0
fi

case "$action" in
  up)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 || true
    wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "${step}+" || true
    ;;
  down)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}-" || true
    ;;
  mute|toggle-mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle || true
    ;;
  *)
    echo "Unknown volume action: $action" >&2
    usage >&2
    exit 2
    ;;
esac

status="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
volume="$(
  awk '
    /Volume:/ {
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^[0-9]+([.][0-9]+)?$/) {
          printf "%.0f\n", $i * 100
          exit
        }
      }
    }
  ' <<<"$status"
)"

if grep -q '\[MUTED\]' <<<"$status"; then
  muted=1
else
  muted=0
fi

if command -v kousen-kiosk-osd >/dev/null 2>&1; then
  if [[ "$action" == "mute" || "$action" == "toggle-mute" ]]; then
    if [[ "$muted" -eq 1 ]]; then
      kousen-kiosk-osd mute on || true
    else
      kousen-kiosk-osd mute off || true
    fi
  else
    if [[ -n "$volume" && "$muted" -eq 1 ]]; then
      kousen-kiosk-osd volume "$volume" --muted || true
    elif [[ -n "$volume" ]]; then
      kousen-kiosk-osd volume "$volume" || true
    fi
  fi
fi
