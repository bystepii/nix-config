{ ... }:
{
  #
  # ========== Host-specific Monitor Spec ==========
  #
  # This uses the nix-config/modules/hosts/common/monitors.nix module which defaults to enabled.
  # Your nix-config/home-manager/<user>/common/optional/desktops/foo.nix WM config should parse and apply these values to its monitor settings
  #
  #  ------   --------   -------
  # | DP-3 | |  DP-4  | | eDP-1 |
  #  ------   --------   -------
  monitors = [
    {
      name = "DP-3";
      width = 1920;
      height = 1080;
      refreshRate = 60;
      x = 0;
      y = 360;
      scale = 1.0;
    }
    {
      name = "DP-4";
      width = 2560;
      height = 1440;
      refreshRate = 60;
      primary = true;
      x = 1920;
      y = 0;
      scale = 1.0;
    }
    {
      name = "eDP-1";
      width = 1920;
      height = 1080;
      refreshRate = 144;
      x = 4480;
      y = 360;
      scale = 1.0;
    }
  ];
}
