{
  config,
  osConfig,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  stylixColors = config.lib.stylix.colors;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.waybar = {
    enable = lib.mkForce false;
  };
  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    customPalettes.stylix = {
      dark = {
        mPrimary = "#${stylixColors.base02}";
        mOnPrimary = "#${stylixColors.base0E}";
        mSecondary = "#${stylixColors.base0F}";
        mOnSecondary = "#${stylixColors.base01}";
        mTertiary = "#${stylixColors.base01}";
        mOnTertiary = "#${stylixColors.base0F}";
        mError = "#${stylixColors.base08}";
        mOnError = "#${stylixColors.base00}";
        mSurface = "#${stylixColors.base00}";
        mOnSurface = "#${stylixColors.base03}";
        mSurfaceVariant = "#${stylixColors.base01}";
        mOnSurfaceVariant = "#${stylixColors.base04}";
        mOutline = "#${stylixColors.base01}";
        mShadow = "#000000";
        mHover = "#${stylixColors.base01}";
        mOnHover = "#${stylixColors.base0A}";

        terminal = {
          background = "#${stylixColors.base00}";
          foreground = "#${stylixColors.base05}";
          cursor = "#${stylixColors.base05}";
          cursorText = "#${stylixColors.base00}";
          selectionBg = "#${stylixColors.base02}";
          selectionFg = "#${stylixColors.base05}";

          normal = {
            black = "#${stylixColors.base00}";
            red = "#${stylixColors.base08}";
            green = "#${stylixColors.base0B}";
            yellow = "#${stylixColors.base0A}";
            blue = "#${stylixColors.base0D}";
            magenta = "#${stylixColors.base0E}";
            cyan = "#${stylixColors.base0C}";
            white = "#${stylixColors.base05}";
          };

          bright = {
            black = "#${stylixColors.base03}";
            red = "#${stylixColors.base08}";
            green = "#${stylixColors.base0B}";
            yellow = "#${stylixColors.base0A}";
            blue = "#${stylixColors.base0D}";
            magenta = "#${stylixColors.base0E}";
            cyan = "#${stylixColors.base0C}";
            white = "#${stylixColors.base07}";
          };
        };
      };
    };

    settings =
      let
        baseSettings = import ./stepii.nix { inherit inputs osConfig; };
        hostConfigPath = lib.custom.relativeToRoot "hosts/nixos/${osConfig.hostSpec.hostName}/noctalia.nix";
        hostSettings = if lib.pathExists hostConfigPath then import hostConfigPath else { };
      in
      lib.recursiveUpdate baseSettings hostSettings;
  };

  home.packages = [
    pkgs.gpu-screen-recorder
    pkgs.slurp
  ];
}
