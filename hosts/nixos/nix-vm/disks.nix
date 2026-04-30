{ ... }:
{
  system.disks = {
    primary = "/dev/vda";
    primaryDiskoLabel = "cryptprimary";
    bootSize = "1G";
    luks.label = "cryptprimary";
    swapSize = null;
    extraDisks = null;
    raidDisks = null;
  };
}
