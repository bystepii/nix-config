{ ... }:
{
  system.disks = {
    primary = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000H1_S340NX0K534821";
    primaryDiskoLabel = "cryptprimary";
    bootSize = "1G";
    luks.label = "cryptprimary";

    lvm = {
      enable = true;
      vgName = "vg0";
    };

    swapSize = "32G";
    swapLocation = "lvm";

    extraDisks = null;
    raidDisks = null;
  };
}
