# This module supports multiple YubiKey 4 and/or 5 devices as well as a single Yubico Security Key device.
# The limitation to a single Security Key is because they do not have serial numbers and therefore the
# scripts in this module cannot uniquely identify them.

{
  config,
  pkgs,
  lib,
  isDarwin,
  ...
}:
let
  homeDirectory = config.hostSpec.home;

  yubikey-up =
    let
      yubikeyIds = lib.concatStringsSep " " (
        lib.mapAttrsToList (name: id: "[${name}]=\"${toString id}\"") config.yubikey.identifiers
      );
    in
    pkgs.writeShellApplication {
      name = "yubikey-up";
      runtimeInputs = [
        pkgs.gawk
        pkgs.yubikey-manager
      ];
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        serial=$(ykman list | awk '{print $NF}')
        # If it got unplugged before we ran, just don't bother
        if [ -z "$serial" ]; then
          exit 0
        fi

        declare -A serials=(${yubikeyIds})

        key_name=""
        for key in "''${!serials[@]}"; do
          if [[ $serial == "''${serials[$key]}" ]]; then
            key_name="$key"
          fi
        done

        if [ -z "$key_name" ]; then
          echo "WARNING: Unidentified yubikey with serial $serial. Won't link an SSH key."
          exit 0
        fi

        echo "Creating links to ${homeDirectory}/.ssh/id_$key_name"
        ln -sf "${homeDirectory}/.ssh/id_$key_name" "${homeDirectory}/.ssh/id_yubikey"
        ln -sf "${homeDirectory}/.ssh/yubikeys/id_$key_name.pub" "${homeDirectory}/.ssh/id_yubikey.pub"
      '';
    };

  yubikey-down = pkgs.writeShellApplication {
    name = "yubikey-down";
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      rm -f "${homeDirectory}/.ssh/id_yubikey"
      rm -f "${homeDirectory}/.ssh/id_yubikey.pub"
    '';
  };

  optionalYubioath =
    if pkgs ? unstable && pkgs.unstable ? yubioath-flutter then
      [ pkgs.unstable.yubioath-flutter ]
    else
      [ ];
in
{
  options.yubikey = {
    enable = lib.mkEnableOption "Enable yubikey support";
    identifiers = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.either lib.types.int lib.types.str);
      description = "Attrset of YubiKey serial numbers.";
      example = lib.literalExample ''
        {
          primary = 12345678;
          backup = 87654321;
          securityKey = "[FIDO]";
        }
      '';
    };
    autoScreenUnlock = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Unlock screen on yubikey insert";
    };
    autoScreenLock = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Lock screen on yubikey removal";
    };
    extractSshSecrets = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Extract keys/ssh/<identifier> secrets to ~/.ssh/id_<identifier>. Keep disabled for PIV/cardno workflows.";
    };
  };

  config = lib.mkIf config.yubikey.enable {
    environment.systemPackages = [
      pkgs.gnupg
      pkgs.yubikey-manager
      pkgs.pam_u2f
      yubikey-up
      yubikey-down
    ]
    ++ optionalYubioath;

    services = lib.optionalAttrs (!isDarwin) {
      udev.extraRules =
        lib.optionalString pkgs.stdenv.isLinux ''
          # Link/unlink ssh key on yubikey add/remove
          SUBSYSTEM=="usb", ACTION=="add", ATTR{idVendor}=="1050", RUN+="${lib.getBin yubikey-up}/bin/yubikey-up"
          # Yubikey 4/5 removal handling differs; matching on HID_NAME covers both
          SUBSYSTEM=="hid", ACTION=="remove", ENV{HID_NAME}=="Yubico Yubi*", RUN+="${lib.getBin yubikey-down}/bin/yubikey-down"
        ''
        + lib.optionalString config.yubikey.autoScreenLock ''
          SUBSYSTEM=="hid", ACTION=="remove", ENV{HID_NAME}=="Yubico Yubi*", RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
        ''
        + lib.optionalString config.yubikey.autoScreenUnlock ''
          SUBSYSTEM=="hid", ACTION=="add", ENV{HID_NAME}=="Yubico YubiKey FIDO", RUN+="${pkgs.systemd}/bin/loginctl activate 1"
        '';

      udev.packages = [ pkgs.yubikey-personalization ];
      pcscd.enable = true;
    };

    security.pam = lib.optionalAttrs pkgs.stdenv.isLinux {
      u2f = {
        enable = true;
        settings = {
          cue = true;
          authFile = "${homeDirectory}/.config/Yubico/u2f_keys";
        };
      };
      services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };
    };
  };
}
