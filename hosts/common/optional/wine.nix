{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # support 64-bit only
    wine64

    # winetricks (all versions)
    winetricks

    # native wayland support (unstable)
    wineWow64Packages.waylandFull
  ];
}
