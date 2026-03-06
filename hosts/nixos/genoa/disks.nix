{ ... }:
{
  system.disks = {
    # 1TB /dev/nvme0n1
    primary = "/dev/disk/by-id/nvme-WD_PC_SN740_SDDQMQD-512G-1001_22491D456004";
    primaryLabel = "cryptprimary";
    bootSize = "512M";
    swapSize = "16G";
    useLuks = true;
  };
}
