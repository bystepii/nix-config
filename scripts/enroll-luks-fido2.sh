#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage:
  ./scripts/enroll-luks-fido2.sh <luks-device-path>

Examples:
  ./scripts/enroll-luks-fido2.sh /dev/vda2
  ./scripts/enroll-luks-fido2.sh /dev/nvme0n1p2

Notes:
- This is a convenience wrapper around systemd-cryptenroll.
- Keep at least one strong fallback passphrase enrolled for recovery.
- Run once per YubiKey you want enrolled.
EOF
}

if [[ ${1-} == "-h" || ${1-} == "--help" ]]; then
	usage
	exit 0
fi

if [[ $# -ne 1 ]]; then
	usage
	exit 1
fi

device="$1"

if [[ ! -b $device ]]; then
	echo "ERROR: '$device' is not a block device" >&2
	exit 1
fi

if ! command -v cryptsetup >/dev/null 2>&1; then
	echo "ERROR: cryptsetup is not installed" >&2
	exit 1
fi

if ! command -v systemd-cryptenroll >/dev/null 2>&1; then
	echo "ERROR: systemd-cryptenroll is not installed" >&2
	exit 1
fi

if ! sudo cryptsetup luksDump "$device" >/dev/null 2>&1; then
	echo "ERROR: '$device' does not appear to be a valid LUKS device" >&2
	exit 1
fi

luks_version="$(sudo cryptsetup luksDump "$device" | awk '/^Version:/ {print $2; exit}')"
if [[ $luks_version != "2" ]]; then
	echo "ERROR: '$device' is LUKS version '$luks_version'. FIDO2 enrollment requires LUKS2." >&2
	exit 1
fi

echo "About to enroll a FIDO2 credential on: $device"
echo "You may be prompted for your current LUKS passphrase and then a YubiKey touch/PIN."
read -r -p "Continue? [y/N] " reply
if [[ ! $reply =~ ^[Yy]$ ]]; then
	echo "Cancelled."
	exit 0
fi

sudo systemd-cryptenroll --fido2-device=auto "$device"

echo
echo "Enrollment complete for this key."
echo "If you have backup YubiKeys, re-run this script once per additional key."
echo "Keep a strong fallback passphrase enrolled for recovery."
