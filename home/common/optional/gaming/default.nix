# This module just provides a customized .desktop file with gamescope args dynamically created based on the
# host's monitors configuration
{
  #  osConfig,
  #  lib,
  pkgs,
  ...
}:

# let
#   monitor = lib.head (lib.filter (m: m.primary) osConfig.monitors);
#
#   steam-session =
#     let
#       gamescope = lib.concatStringsSep " " [
#         (lib.getExe pkgs.unstable.gamescope)
#         "--output-width ${lib.toString monitor.width}"
#         "--output-height ${lib.toString monitor.height}"
#         "--framerate-limit ${lib.toString monitor.refreshRate}"
#         "--prefer-output ${monitor.name}"
#         "--adaptive-sync"
#         "--expose-wayland"
#         "--steam"
#         "--hdr-enabled"
#       ];
#       steam = lib.concatStringsSep " " [
#         "steam"
#       ];
#     in
#     pkgs.writeTextDir "share/applications/steam-gamescope.desktop" ''
#       [Desktop Entry]
#       Name=Steam gamescope
#       Exec=${gamescope} -- ${steam}
#       Icon=steam
#       Type=Application
#     '';
# in
{
  #   home.packages = [
  #    steam-session
  # ]
  # ++ lib.attrValues {
  #   inherit (pkgs.unstable)
  #     #rusty-path-of-building
  #     ;
  # };

  home.packages = with pkgs; [ prismlauncher ];

}
