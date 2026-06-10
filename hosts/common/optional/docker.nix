{
  config,
  lib,
  ...
}:
{
  virtualisation.docker = {
    enable = true;
    daemon.settings.features.cdi = true;
  };

  users.users.${config.hostSpec.primaryUsername} = {
    extraGroups = [ "docker" ];
  };

  environment.persistence = lib.mkIf config.hostSpec.isImpermanent {
    "${config.hostSpec.persistFolder}".directories = [
      "/var/lib/docker"
    ];
  };
}
