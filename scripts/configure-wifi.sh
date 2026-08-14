#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo kousen-configure-wifi" >&2
  exit 1
fi

if ! command -v nmcli >/dev/null 2>&1; then
  echo "nmcli is required. Install NetworkManager first." >&2
  exit 1
fi

nmcli radio wifi on
nmcli device wifi rescan || true

echo "Available WiFi networks:"
nmcli --fields SSID,SECURITY,SIGNAL device wifi list
echo

read -r -p "SSID: " ssid
if [[ -z "$ssid" ]]; then
  echo "SSID is required." >&2
  exit 1
fi

read -r -s -p "Password, leave blank for open network: " password
echo

if [[ -z "$password" ]]; then
  nmcli device wifi connect "$ssid"
else
  nmcli device wifi connect "$ssid" password "$password"
fi

echo "WiFi connection saved for SSID: $ssid"
