{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.luksFido2;
in
{
  options.luksFido2 = {
    enable = lib.mkEnableOption "FIDO2 token unlock for LUKS volumes during boot";

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ config.system.disks.luks.label ];
      defaultText = lib.literalExpression "[ config.system.disks.luks.label ]";
      description = ''
        List of LUKS device names (as used in `boot.initrd.luks.devices`) to enable
        FIDO2 unlock for. Defaults to the primary disk's LUKS label.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure systemd stage 1 knows to look for FIDO2 tokens for the specified devices.
    # This adds the `fido2-device=auto` crypttab option, causing systemd-cryptsetup
    # to prompt for a FIDO2 token instead of (or in addition to) a passphrase.
    boot.initrd.luks.devices = lib.genAttrs cfg.devices (_: {
      crypttabExtraOpts = [
        "fido2-device=auto"
        "token-timeout=10s"
      ];
    });

    # Ensure libfido2 is available in stage-1 initrd for systemd-cryptsetup
    boot.initrd.systemd.packages = [ pkgs.libfido2 ];
  };
}
