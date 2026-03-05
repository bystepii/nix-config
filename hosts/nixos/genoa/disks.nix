{ ... }:
{
  system.disks = {
    primary = "/dev/nvme0n1";
    primaryLabel = "cryptprimary";
    bootSize = "512M";
    swapSize = "16G";
    useLuks = true;
  };
}
