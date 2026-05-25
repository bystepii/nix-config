{ ... }:
{
  system.disks = {
    primary = "/dev/disk/by-id/nvme-KIOXIA-EXCERIA_PRO_SSD_43FA20DMKMU6";
    primaryDiskoLabel = "cryptprimary";
    bootSize = "1G";
    luks.label = "cryptprimary";

    # LVM configuration
    lvm = {
      enable = true;
      vgName = "vg0";
    };

    # Swap on LVM LV
    swapSize = "64G";
    swapLocation = "lvm";

    extraDisks = null;
    raidDisks = null;
  };
}
