{ lib, pkgs, ... }:
{
  hardware.xpadneo.enable = true;

  environment.systemPackages = lib.attrValues {
    inherit (pkgs)
      lsfg-vk
      lsfg-vk-ui
      ;
  };
  programs = {
    steam = {
      enable = true;
      package = pkgs.unstable.steam;
      protontricks = {
        enable = true;
        package = pkgs.unstable.protontricks;
      };
      extraCompatPackages = [ pkgs.unstable.proton-ge-bin ];
    };
    # To run steam games in game mode, add the following to the game's properties within steam
    # `gamemoderun %command%`
    gamemode = {
      enable = true;
      settings = {
        #see gamemode man page for settings info
        general = {
          softrealtime = "on";
          inhibit_screensaver = 1;
        };
        gpu = {
          #apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 1; # The DRM device number on the system (usually 0), ie. the number in /sys/class/drm/card0/
          amd_performance_level = "high";
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
  };
}
