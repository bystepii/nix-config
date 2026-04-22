{
  config,
  lib,
  ...
}:
let
  cfg = config.batteryPowerServices;
in
{
  options.batteryPowerServices = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable battery power services.";
    };
  };
  config = lib.mkIf cfg.enable {
    # These are the ones used by noctalia
    services = {
      upower.enable = true;
      power-profiles-daemon.enable = true;
    };
  };
}
