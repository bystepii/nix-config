{ ... }:
{
  system.disks = {
    primary = "/dev/vda";
    bootSize = "512M";
    useLuks = false;
  };
}
