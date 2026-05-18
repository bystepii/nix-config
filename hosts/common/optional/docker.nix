{
  config,
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
}
