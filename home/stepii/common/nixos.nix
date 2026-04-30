# Core home functionality that will only work on Linux
{
  config,
  lib,
  # secrets,
  ...
}:
let
  home = config.home.homeDirectory;
in
{
  home = {
    sessionPath = lib.flatten ([
      "${home}/scripts/"
    ]
    # ++ lib.optional osConfig.hostSpec.isWork secrets.work.extraPaths
    );
  };
}
