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
        "video" # in part, for local llm gpu access
        "render" # for local llm gpu access
        "docker"
        "git"
        "networkmanager"
        "scanner" # for print/scan"
        "lp" # for print/scan"
      ])
    ];
}
