{ ... }:
{
  # Reuse shared disk module instead of host-local disko args.
  system.disks = {
    enable = true;
    primary = "/dev/vda";
    useLuks = true;
    swapSize = 4;
  };
}
