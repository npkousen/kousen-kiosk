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

refresh_status() {
  for _ in 1 2 3 4 5; do
    if wpctl status >"$status_file" 2>"$error_file"; then
      return 0
    fi
    cat "$error_file" || true
    sleep 1
  done
  return 1
}

digital_sink_id() {
  awk '
    /Sinks:/ { in_sinks=1; next }
    /Sources:/ { in_sinks=0 }
    in_sinks && /(HDMI|DisplayPort|Digital)/ {
      line=$0
      gsub(/^[^0-9]*/, "", line)
      split(line, parts, ".")
      print parts[1]
      exit
    }
  ' "$status_file"
}

available_digital_profile() {
  pw-cli enum-params "$1" EnumProfile 2>/dev/null | awk '
    function emit_if_match() {
      if (!found && profile_index != "" && available && digital) {
        print profile_index
        found=1
      }
    }

    /^  Object:/ {
      emit_if_match()
      profile_index=""
      available=0
      digital=0
      next
    }

    /Profile:index/ {
      getline
      if ($1 == "Int") profile_index=$2
      next
    }

    /Profile:name/ {
      getline
      text=tolower($0)
      if (text ~ /hdmi|displayport|digital/) digital=1
      next
    }

    /Profile:description/ {
      getline
      text=tolower($0)
      if (text ~ /hdmi|displayport|digital/) digital=1
      next
    }

    /Profile:available/ {
      getline
      if ($0 ~ /ParamAvailability:yes/) available=1
      next
    }

    END {
      emit_if_match()
    }
  '
}

maybe_enable_digital_profile() {
  if [[ -n "$(digital_sink_id)" ]]; then
    return 0
  fi

  mapfile -t device_ids < <(
    awk '
      /Devices:/ { in_devices=1; next }
      /Sinks:/ { in_devices=0 }
      in_devices && /\[alsa\]/ {
        line=$0
        gsub(/^[^0-9]*/, "", line)
        split(line, parts, ".")
        print parts[1]
      }
    ' "$status_file"
  )

  for device_id in "${device_ids[@]}"; do
    profile_index="$(available_digital_profile "$device_id" | head -n 1 || true)"
    if [[ -z "$profile_index" ]]; then
      continue
    fi

    echo "Switching audio device $device_id to digital profile $profile_index"
    if wpctl set-profile "$device_id" "$profile_index"; then
      sleep 1
      refresh_status || true
      return 0
    fi
  done
}

refresh_status || true

if [[ ! -s "$status_file" ]]; then
  echo "PipeWire is not ready"
  exit 0
fi

cat "$status_file"

maybe_enable_digital_profile

sink_id="$(digital_sink_id)"

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
