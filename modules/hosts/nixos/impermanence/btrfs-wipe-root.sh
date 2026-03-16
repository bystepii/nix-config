#!/usr/bin/env bash
# Reset root by moving current @root to @old_roots and creating a fresh @root.
set -euo pipefail

ROOT_DEVICE="${ROOT_DEVICE:-/dev/vda}"
OLD_ROOT_RETENTION_DAYS="${OLD_ROOT_RETENTION_DAYS:-30}"

mkdir -p /btrfs_tmp
mount -t btrfs -o subvol=/ "${ROOT_DEVICE}" /btrfs_tmp

if [[ -e /btrfs_tmp/@root ]]; then
	mkdir -p /btrfs_tmp/@old_roots
	timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@root)" "+%Y-%m-%d_%H:%M:%S")
	mv /btrfs_tmp/@root "/btrfs_tmp/@old_roots/${timestamp}"
fi

delete_subvolume_recursively() {
	local target="$1"
	while IFS= read -r subvolume; do
		delete_subvolume_recursively "/btrfs_tmp/${subvolume}"
	done < <(btrfs subvolume list -o "${target}" | cut -f 9- -d ' ')
	btrfs subvolume delete "${target}"
}

if [[ -d /btrfs_tmp/@old_roots ]]; then
	find /btrfs_tmp/@old_roots -mindepth 1 -maxdepth 1 -mtime +"${OLD_ROOT_RETENTION_DAYS}" | while IFS= read -r old; do
		delete_subvolume_recursively "${old}"
	done
fi

btrfs subvolume create /btrfs_tmp/@root
umount /btrfs_tmp
rmdir /btrfs_tmp || true
