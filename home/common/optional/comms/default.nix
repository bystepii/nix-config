{ lib, pkgs, ... }:
{
  # introdus.signal.enable = true;

  home.packages = lib.attrValues {
    inherit (pkgs)
      discord
      #telegram-desktop
      #slack
      ;
  };
}
