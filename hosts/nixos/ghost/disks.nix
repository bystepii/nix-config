{ ... }:
let
  extraDisk1 = "cryptextra";
  extraDisk2 = "cryptvms";
in
{
  system.disks = {
    # 1TB /dev/nvme0n1
    primary = "/dev/disk/by-id/nvme-WDS100T3XHC-00SJG0_201274802169";
    primaryLabel = "cryptprimary";
    bootSize = "1G";
    useLuks = true;
    extraDisks = [
      # NOTE: the luks partition (e.g. `-part1`) needs to be specified in path
      {
        # 250GB /dev/nvme1n1
        name = extraDisk1;
        path = "/dev/disk/by-id/nvme-WDS250G3X0C-00SJG0_202604A00429-part1";
      }
      {
        # 500GB /dev/sda
        name = extraDisk2;
        path = "/dev/disk/by-id/ata-WDC_WDS500G2B0A-00SM50_201723800798-part1";
      }
    ];
  };
  # define mount points
  # auto-unlocking handled via nix-config/modules/disks.nix module based on
  # extraDisks entries above
  # FIXME: some of these options may be redundant with crypttab options but it's
  # working
  fileSystems."/mnt/extra" = {
    device = "/dev/mapper/${extraDisk1}";
    fsType = "btrfs";
    options = [
      "subvol=@extra"
      "compress=zstd"
      "nofail"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
    ];
  };
  fileSystems."/mnt/vms" = {
    device = "/dev/mapper/${extraDisk2}";
    fsType = "btrfs";
    options = [
      "subvol=@vms"
      "compress=zstd"
      "nofail"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10s"
    ];
  };
}
