{ config, ... }:
let
  scaling = config.hostSpec.scaling;
in
{
  #
  # ========== Host-specific Monitor Spec ==========
  #
  # This uses the nix-config/modules/home/montiors.nix module which defaults to enabled.
  # Your nix-config/home-manger/<user>/common/optional/desktops/foo.nix WM config should parse and apply these values to it's monitor settings
  #
  #           ------
  #        | HDMI-A-1 |
  #           ------
  #  ------   ------   ------
  # | DP-2 | | DP-1 | | DP-3 |
  #  ------   ------   ------
  monitors = [
    {
      name = "DP-2";
      width = 2560;
      height = 2880;
      refreshRate = 60;
      x = -2560;
      workspace = "8";
      scale = scaling;
    }
    {
      name = "DP-1";
      width = 3840;
      height = 2160;
      refreshRate = 60;
      vrr = 1;
      primary = true;
      scale = scaling;
    }
    {
      name = "DP-3";
      width = 2560;
      height = 2880;
      refreshRate = 60;
      x = 3840;
      workspace = "10";
      scale = scaling;
    }
    {
      name = "HDMI-A-1";
      width = 2560;
      height = 1440;
      refreshRate = 144;
      y = -1440;
      transform = 2;
      workspace = "9";
      #scale = config.hostSpec.scaling; #not needed, resolution too low
    }
  ];
}
