{
  config,
  lib,
  ...
}:
{
  virtualisation.docker = {
    enable = true;
    daemon.settings.features = {
      cdi = true;
      containerd-snapshotter = true;
    };
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
