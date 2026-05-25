{ ... }:
{
  #
  # ========== Host-specific Monitor Spec ==========
  #
  # This uses the nix-config/modules/hosts/common/monitors.nix module which defaults to enabled.
  # Your nix-config/home-manager/<user>/common/optional/desktops/foo.nix WM config should parse and apply these values to its monitor settings
  #
  #  ------   ------
  # | DP-5 | | DP-6 |
  #  ------   ------
  monitors = [
    {
      name = "DP-5";
      width = 2560;
      height = 1440;
      refreshRate = 165;
      primary = true;
      x = 0;
      y = 0;
      scale = 1.0;
    }
    {
      name = "DP-6";
      width = 2560;
      height = 1440;
      refreshRate = 165;
      x = 2560;
      y = 0;
      scale = 1.0;
      workspace = "9";
    }
  ];
}
