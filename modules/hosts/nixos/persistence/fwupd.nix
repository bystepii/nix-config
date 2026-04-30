{
  config,
  lib,
  ...
}:
{
  # config = lib.mkIf (config.services.fwupd.enable && config.introdus.impermanence.enable) {
  config = lib.mkIf (config.services.fwupd.enable && config.hostSpec.isImpermanent) {
    environment.persistence."${config.hostSpec.persistFolder}".directories = [
      "/var/cache/fwupd"
      "/var/lib/fwupd"
    ];
  };
}
