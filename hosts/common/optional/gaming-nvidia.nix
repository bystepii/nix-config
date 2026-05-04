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

    gamemode = {
      enable = true;
      settings = {
        general = {
          softrealtime = "on";
          inhibit_screensaver = 1;
        };
        gpu = {
          gpu_device = 0;
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
  };
}
