# User config applicable only to nixos
{
  config,
  lib,
  ...
}:
{
  isNormalUser = true;
  extraGroups =
    let
      ifTheyExist = groups: lib.filter (group: lib.hasAttr group config.users.groups) groups;
    in
    lib.flatten [
      "wheel"
      (ifTheyExist [
        "audio"
        "video"
        "docker"
        "git"
        "networkmanager"
        "scanner"
        "lp"
      ])
    ];
}
