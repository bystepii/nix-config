#!/usr/bin/env bash
# Check ephemeral files in current @root or diff against an old root snapshot.
set -euo pipefail

help_and_exit() {
	echo
	echo "Check current root for files not persisted by impermanence."
	echo
	echo "USAGE: $0 [OPTIONS]"
	echo
	echo "OPTIONS:"
	echo "  -b=<btrfs_vol>  btrfs volume to mount (default from BTRFS_VOL env)"
	echo "  -s=<snapshot>   old snapshot under @old_roots to diff against"
	echo "  --list-old      list old root snapshots"
	echo "  -h, --help      show this help and exit"
	echo
	exit 1
}

if [[ $UID -ne 0 ]]; then
	echo "ERROR: run as root so the btrfs volume can be mounted" >&2
	exit 1
fi

SNAPSHOT=""
MOUNTDIR=$(mktemp -d)
BTRFS_VOL="${BTRFS_VOL:-/dev/vda}"
ROOT_LABEL="@root"
OLD_ROOTS_LABEL="@old_roots"
LIST_OLD=0

while [[ $# -gt 0 ]]; do
	case "$1" in
	--list-old)
		LIST_OLD=1
		;;
	-b=*)
		BTRFS_VOL="${1#*=}"
		;;
	-s=*)
		SNAPSHOT="${1#*=}"
		;;
	-h | --help)
		help_and_exit
		;;
	*)
		echo "ERROR: invalid option: $1" >&2
		help_and_exit
		;;
	esac
	shift
done

mount -t btrfs -o subvol=/ "${BTRFS_VOL}" "${MOUNTDIR}"
ROOT_SUBVOL="${MOUNTDIR}/${ROOT_LABEL}"
OLD_ROOTS_SUBVOL="${MOUNTDIR}/${OLD_ROOTS_LABEL}"

if [[ ${LIST_OLD} -eq 1 ]]; then
	echo "Old roots:"
	if [[ -d ${OLD_ROOTS_SUBVOL} ]]; then
		(cd "${OLD_ROOTS_SUBVOL}" && find . -mindepth 1)
	fi
else
	ROOT_FILES=$(cd "${ROOT_SUBVOL}" && fd -I -H --type file --exclude '/tmp' | sort)

	if [[ -n ${SNAPSHOT} ]]; then
		SNAPSHOT_SUBVOL="${OLD_ROOTS_SUBVOL}/${SNAPSHOT}"
		if [[ ! -d ${SNAPSHOT_SUBVOL} ]]; then
			echo "ERROR: snapshot ${SNAPSHOT} does not exist" >&2
			umount "${MOUNTDIR}"
			rmdir "${MOUNTDIR}"
			exit 1
		fi

		SNAPSHOT_FILES=$(cd "${SNAPSHOT_SUBVOL}" && fd -I -H --type file --exclude '/tmp' | sort)
		echo "Files in ${SNAPSHOT} that are missing from current root:"
		while IFS= read -r file; do
			if [[ ! ${ROOT_FILES} =~ ${file} ]]; then
				eza "${SNAPSHOT_SUBVOL}/${file}"
			fi
		done <<<"${SNAPSHOT_FILES}"
	else
		echo "Ephemeral files on current root:"
		while IFS= read -r file; do
			eza "${ROOT_SUBVOL}/${file}"
		done <<<"${ROOT_FILES}"
	fi
fi

umount "${MOUNTDIR}"
rmdir "${MOUNTDIR}"
