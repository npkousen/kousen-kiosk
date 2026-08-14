#!/usr/bin/env bash
set -euo pipefail

KIOSK_USER="${KIOSK_USER:-kiosk}"

if [[ "${EUID}" -eq 0 && -z "${KOUSEN_AUDIO_AS_KIOSK:-}" ]] && id "$KIOSK_USER" >/dev/null 2>&1; then
  kiosk_uid="$(id -u "$KIOSK_USER")"
  exec runuser -u "$KIOSK_USER" -- env \
    KOUSEN_AUDIO_AS_KIOSK=1 \
    XDG_RUNTIME_DIR="/run/user/${kiosk_uid}" \
    "$0" "$@"
fi

if [[ "$(id -un)" != "$KIOSK_USER" ]]; then
  echo "Note: this is running as $(id -un). For kiosk audio defaults, run: sudo kousen-configure-audio" >&2
  echo
fi

echo "ALSA playback devices:"
aplay -l || true
echo

if ! command -v wpctl >/dev/null 2>&1; then
  echo "wpctl is not installed. Run the kiosk installer first." >&2
  exit 1
fi

if [[ "${1:-}" == "set-default" ]]; then
  if [[ -z "${2:-}" ]]; then
    echo "Usage: sudo kousen-configure-audio set-default <sink-id>" >&2
    exit 1
  fi
  wpctl set-default "$2"
  echo "Set default audio sink to: $2"
  exit 0
fi

echo "PipeWire/WirePlumber status:"
wpctl status
echo
echo "To set HDMI as default, find the HDMI sink id above and run:"
echo
echo "  sudo kousen-configure-audio set-default <sink-id>"
echo
echo "Example:"
echo
echo "  sudo kousen-configure-audio set-default 42"
