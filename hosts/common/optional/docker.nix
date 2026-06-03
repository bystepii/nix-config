{
  config,
  lib,
  ...
}:
{
  virtualisation.docker = {
    enable = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  users.users.${config.hostSpec.primaryUsername} = {
    extraGroups = [ "docker" ];
  };

  environment.persistence = lib.mkIf config.hostSpec.isImpermanent {
    "${config.hostSpec.persistFolder}".directories = [
      "/var/lib/docker"
    ];
  };
}
