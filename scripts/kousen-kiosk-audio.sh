#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${HOME}/.local/share/kousen-kiosk"
LOG_FILE="${LOG_DIR}/audio.log"
mkdir -p "$LOG_DIR"

exec >> "$LOG_FILE" 2>&1

echo "=== $(date -Is) selecting audio output ==="

if ! command -v wpctl >/dev/null 2>&1; then
  echo "wpctl is not installed"
  exit 0
fi

status_file="$(mktemp)"
error_file="$(mktemp)"
cleanup() {
  rm -f "$status_file" "$error_file"
}
trap cleanup EXIT

for _ in 1 2 3 4 5; do
  if wpctl status >"$status_file" 2>"$error_file"; then
    break
  fi
  cat "$error_file" || true
  sleep 1
done

if [[ ! -s "$status_file" ]]; then
  echo "PipeWire is not ready"
  exit 0
fi

cat "$status_file"

sink_id="$(
  awk '
    /Sinks:/ { in_sinks=1; next }
    /Sources:/ { in_sinks=0 }
    in_sinks && /HDMI/ {
      line=$0
      gsub(/^[^0-9]*/, "", line)
      split(line, parts, ".")
      print parts[1]
      exit
    }
  ' "$status_file"
)"

if [[ -z "$sink_id" ]]; then
  sink_id="$(
    awk '
      /Sinks:/ { in_sinks=1; next }
      /Sources:/ { in_sinks=0 }
      in_sinks && /Analog/ && $0 !~ /USB/ {
        line=$0
        gsub(/^[^0-9]*/, "", line)
        split(line, parts, ".")
        print parts[1]
        exit
      }
    ' "$status_file"
  )"
fi

if [[ -z "$sink_id" ]]; then
  sink_id="$(
    awk '
      /Sinks:/ { in_sinks=1; next }
      /Sources:/ { in_sinks=0 }
      in_sinks && /[0-9]+[.]/ {
        line=$0
        gsub(/^[^0-9]*/, "", line)
        split(line, parts, ".")
        print parts[1]
        exit
      }
    ' "$status_file"
  )"
fi

if [[ -z "$sink_id" ]]; then
  echo "No audio sink found"
  exit 0
fi

echo "Selected sink: $sink_id"
wpctl set-default "$sink_id" || true
wpctl set-volume "$sink_id" 0.75 || true
