#!/usr/bin/env bash
set -euo pipefail

remote_repo="${KOUSEN_REMOTE_REPO:-https://github.com/npkousen/kousen-remote.git}"
source_dir="${KOUSEN_REMOTE_SOURCE_DIR:-/opt/kousen-remote-source}"
install_dir="${KOUSEN_REMOTE_INSTALL_DIR:-/opt/kousen-remote}"
remote_device="${KOUSEN_REMOTE_DEVICE:-}"
start_service=1

usage() {
  cat <<'EOF'
Usage: sudo ./scripts/install-kousen-remote.sh [options]

Options:
  --repo URL             Public git repository URL.
                         Default: https://github.com/npkousen/kousen-remote.git
  --source-dir PATH      Clone/update source path. Default: /opt/kousen-remote-source
  --install-dir PATH     Runtime install path. Default: /opt/kousen-remote
  --device ADDRESS       Paired Bluetooth remote address or BlueZ object path.
  --no-start             Enable the systemd service but do not start it now.
  -h, --help             Show this help.

Without --device, this installs the kousen-remote CLI and Bluetooth/Python
dependencies, but does not create or enable kousen-remote.service.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      remote_repo="${2:?missing value for --repo}"
      shift 2
      ;;
    --source-dir)
      source_dir="${2:?missing value for --source-dir}"
      shift 2
      ;;
    --install-dir)
      install_dir="${2:?missing value for --install-dir}"
      shift 2
      ;;
    --device)
      remote_device="${2:?missing value for --device}"
      shift 2
      ;;
    --no-start)
      start_service=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo because this writes /opt, /usr/local/bin, /etc/default, and systemd files." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer currently supports Debian/Ubuntu systems with apt-get." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  bluez \
  git \
  python3-dbus-next \
  python3-evdev \
  python3-pip \
  python3-venv

systemctl enable --now bluetooth.service || true

if [[ -d "${source_dir}/.git" ]]; then
  git -C "${source_dir}" fetch --prune origin
  git -C "${source_dir}" checkout main
  git -C "${source_dir}" pull --ff-only origin main
elif [[ -e "${source_dir}" ]] && [[ -n "$(find "${source_dir}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  echo "${source_dir} exists and is not an empty git checkout." >&2
  exit 1
else
  mkdir -p "$(dirname "${source_dir}")"
  git clone --depth 1 "${remote_repo}" "${source_dir}"
fi

mkdir -p "${install_dir}"
tar \
  --exclude='./.git' \
  --exclude='./.venv' \
  --exclude='./__pycache__' \
  --exclude='*/__pycache__' \
  -C "${source_dir}" \
  -cf - . | tar -C "${install_dir}" -xf -

python3 -m venv --system-site-packages "${install_dir}/.venv"
"${install_dir}/.venv/bin/python" -m pip install --no-deps -e "${install_dir}"

cat > /usr/local/bin/kousen-remote <<EOF
#!/usr/bin/env bash
set -euo pipefail

profile_dir="\${KOUSEN_REMOTE_PROFILE_DIR:-${install_dir}/profiles}"
remote_bin="${install_dir}/.venv/bin/kousen-remote"

show_devices() {
  output_file="\$(mktemp)"
  if timeout 10 "\${remote_bin}" --profiles "\${profile_dir}" devices "\$@" >"\${output_file}"; then
    if [[ -s "\${output_file}" ]]; then
      cat "\${output_file}"
      rm -f "\${output_file}"
      return 0
    fi

    rm -f "\${output_file}"
    echo "No scored remote candidates found; showing raw Bluetooth devices instead." >&2
    bluetoothctl devices
    return 0
  fi

  status="\$?"
  cat "\${output_file}" || true
  rm -f "\${output_file}"
  if [[ "\${status}" == "124" ]]; then
    echo "kousen-remote device scoring timed out; showing raw Bluetooth devices instead." >&2
    bluetoothctl devices
    return 0
  fi
  return "\${status}"
}

if [[ "\${1:-}" == "devices" ]]; then
  shift
  show_devices "\$@"
  exit "\$?"
fi

inspect_scan_candidates() {
  scan_log="\${1:?missing scan log}"
  found=0

  while IFS= read -r address; do
    [[ -n "\${address}" ]] || continue
    info="\$(bluetoothctl info "\${address}" 2>/dev/null || true)"
    [[ -n "\${info}" ]] || continue

    score=0
    matches=()
    if grep -qi 'ManufacturerData.Key: 0x004c' <<<"\${info}"; then
      score=\$((score + 35))
      matches+=("Apple manufacturer data 0x004c")
    fi
    if grep -qi '00001812-0000-1000-8000-00805f9b34fb' <<<"\${info}"; then
      score=\$((score + 30))
      matches+=("Bluetooth HID service 00001812")
    fi
    if grep -qi 'Appearance: 0x03c0' <<<"\${info}"; then
      score=\$((score + 20))
      matches+=("HID remote-control appearance 0x03c0")
    fi
    if grep -qi 'bluetooth:v004Cp0315d0001' <<<"\${info}"; then
      score=\$((score + 50))
      matches+=("Siri Remote modalias v004c/p0315")
    fi

    if [[ "\${score}" -gt 0 ]]; then
      found=1
      if [[ "\${score}" -ge 55 ]]; then
        echo
        echo "Likely Siri Remote candidate: \${address}  score=\${score}"
      else
        echo
        echo "Possible Apple/HID candidate: \${address}  score=\${score}"
      fi
      printf '  Matched:'
      printf ' %s;' "\${matches[@]}"
      printf '\n'
      echo "\${info}" | sed -n '/Alias:/p;/Appearance:/p;/Paired:/p;/Bonded:/p;/Trusted:/p;/Connected:/p;/UUID:/p;/ManufacturerData.Key:/,+2p;/Modalias:/p'
    fi
  done < <(awk '/^\[(NEW|CHG)\] Device/ { print \$3 }' "\${scan_log}" | sort -u)

  if [[ "\${found}" -eq 0 ]]; then
    echo
    echo "No Apple HID remote candidates found."
    echo "For a Siri Remote, put it in pairing mode near this PC: Back/Menu + Volume Up for 5 seconds."
  fi
}

if [[ "\${1:-}" == "scan" ]]; then
  shift
  seconds="8"
  devices_args=()
  no_hid_filter=0
  while [[ \$# -gt 0 ]]; do
    case "\$1" in
      --seconds)
        seconds="\${2:?missing value for --seconds}"
        shift 2
        ;;
      --all)
        devices_args+=(--all)
        shift
        ;;
      --no-hid-filter)
        no_hid_filter=1
        shift
        ;;
      *)
        echo "Unknown scan argument: \$1" >&2
        exit 2
        ;;
    esac
  done

  scan_log="\$(mktemp)"
  {
    printf 'power on\n'
    printf 'pairable on\n'
    if [[ "\${no_hid_filter}" -eq 0 ]]; then
      printf 'menu scan\n'
      printf 'transport le\n'
      printf 'uuids 00001812-0000-1000-8000-00805f9b34fb\n'
      printf 'back\n'
    fi
    printf 'scan on\n'
    sleep "\${seconds}"
    printf 'scan off\n'
    printf 'quit\n'
  } | bluetoothctl | tee "\${scan_log}"

  inspect_scan_candidates "\${scan_log}"
  rm -f "\${scan_log}"
  exit 0
fi

exec "\${remote_bin}" --profiles "\${profile_dir}" "\$@"
EOF
chmod 0755 /usr/local/bin/kousen-remote

echo "Installed kousen-remote CLI at /usr/local/bin/kousen-remote"

if [[ -z "${remote_device}" ]]; then
  echo "No remote device supplied; systemd service was not configured."
  echo "Pair a remote later, then rerun with: --device XX:XX:XX:XX:XX:XX"
  exit 0
fi

install -m 0644 "${install_dir}/packaging/systemd/kousen-remote.service" /etc/systemd/system/kousen-remote.service
install -m 0644 "${install_dir}/packaging/systemd/kousen-remote.default" /etc/default/kousen-remote

escaped_device="$(printf '%s' "${remote_device}" | sed 's/[&|]/\\&/g')"
escaped_mapping="$(printf '%s' "${install_dir}/mappings/kiosk-browser.json" | sed 's/[&|]/\\&/g')"
escaped_bin="$(printf '%s' "${install_dir}/.venv/bin/kousen-remote" | sed 's/[&|]/\\&/g')"

sed -i "s|^KOUSEN_REMOTE_DEVICE=.*|KOUSEN_REMOTE_DEVICE=${escaped_device}|" /etc/default/kousen-remote
sed -i "s|^KOUSEN_REMOTE_MAPPING=.*|KOUSEN_REMOTE_MAPPING=${escaped_mapping}|" /etc/default/kousen-remote
sed -i "s|/opt/kousen-remote/.venv/bin/kousen-remote|${escaped_bin}|" /etc/systemd/system/kousen-remote.service

systemctl daemon-reload
systemctl enable kousen-remote.service

if [[ "${start_service}" -eq 1 ]]; then
  systemctl restart kousen-remote.service
fi

systemctl --no-pager status kousen-remote.service || true
