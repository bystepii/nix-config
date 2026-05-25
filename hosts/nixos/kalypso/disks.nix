{ ... }:
{
  system.disks = {
    primary = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B73815C3B99";
    primaryDiskoLabel = "cryptprimary";
    bootSize = "1G";
    luks.label = "cryptprimary";
    swapSize = null;
    extraDisks = null;
    raidDisks = null;
  };
}
