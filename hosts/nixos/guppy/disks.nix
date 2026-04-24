{ ... }:
{
  system.disks = {
    primary = "/dev/vda";
    bootSize = "512M";
    luks.enable = false;
  };
}
