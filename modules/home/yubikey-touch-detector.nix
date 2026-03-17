# Home-manager module for YubiKey touch detection notifications.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.yubikey-touch-detector;
in
{
  options.services.yubikey-touch-detector = {
    enable = lib.mkEnableOption "a tool to detect when your YubiKey is waiting for a touch";

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--libnotify" ];
      defaultText = lib.literalExpression ''[ "--libnotify" ]'';
      description = "Extra arguments to pass to yubikey-touch-detector.";
    };

    notificationSound = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Play sounds when the YubiKey is waiting for a touch.";
    };

    notificationSoundFile = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/window-attention.oga";
      description = "Path to a sound file played when the YubiKey is waiting for a touch.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.yubikey-touch-detector ];

    systemd.user.services.yubikey-touch-detector = {
      Unit = {
        Description = "Detects when your YubiKey is waiting for a touch";
      };
      Service = {
        ExecStart = "${lib.getExe' pkgs.yubikey-touch-detector "yubikey-touch-detector"} ${lib.concatStringsSep " " cfg.extraArgs}";
        Environment = [ "PATH=${lib.makeBinPath [ pkgs.gnupg ]}" ];
        Restart = "on-failure";
        RestartSec = "1sec";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    systemd.user.services.yubikey-touch-detector-sound =
      let
        file = cfg.notificationSoundFile;
        yubikey-play-sound = pkgs.writeShellApplication {
          name = "yubikey-play-sound";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.mpv
            pkgs.netcat
          ];
          text = ''
            socket="''${XDG_RUNTIME_DIR:-/run/user/$UID}/yubikey-touch-detector.socket"

            while true; do
              if [ ! -e "$socket" ]; then
                printf "Waiting for YubiKey socket %s\n" "$socket"
                while [ ! -e "$socket" ]; do sleep 1; done
              fi
              printf "Detected %s is up\n" "$socket"

              nc -U "$socket" | while read -r -n5 cmd; do
                if [ "''${cmd:4:1}" = "1" ]; then
                  printf "Playing %s\n" "${file}"
                  mpv --volume=100 "${file}" > /dev/null
                else
                  printf "Ignored yubikey command: %s\n" "$cmd"
                fi
              done

              sleep 1
            done
          '';
        };
      in
      lib.mkIf cfg.notificationSound {
        Unit = {
          Description = "Play sound when the YubiKey is waiting for a touch";
          Requires = [ "yubikey-touch-detector.service" ];
        };
        Service = {
          ExecStart = lib.getExe' yubikey-play-sound "yubikey-play-sound";
          Restart = "on-failure";
          RestartSec = "1sec";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
  };
}
