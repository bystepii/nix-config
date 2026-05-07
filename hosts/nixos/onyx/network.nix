{ lib, ... }:
{
  # Disable facter-generated per-interface DHCP config so we can boot
  # on different hardware (e.g. external SSD on laptop vs desktop)
  # without waiting for missing interfaces to time out.
  facter.detected.dhcp.enable = false;

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };
}
