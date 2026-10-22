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
      };
    };

    settings =
      let
        baseSettings = import ./stepii.nix;
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
