{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.gparted
    # Default runtime tools
    pkgs.dosfstools # FAT12/16/32
    pkgs.e2fsprogs # ext2/3/4
    # Extended filesystem support
    # pkgs.bcachefs-tools  # Bcachefs (experimental) - disabled: may trigger systemd units
    pkgs.btrfs-progs # Btrfs
    pkgs.exfatprogs # exFAT
    pkgs.f2fs-tools # F2FS
    pkgs.jfsutils # JFS
    # pkgs.cryptsetup      # LUKS - disabled: triggers cryptsetup.target
    # pkgs.lvm2            # LVM - disabled: triggers lvm2-monitor.service
    pkgs.nilfs-utils # NILFS
    pkgs.ntfs3g # NTFS
    pkgs.udftools # UDF
    pkgs.xfsprogs # XFS
    pkgs.xfsdump # XFS dump
  ];
}
