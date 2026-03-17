# git is core no matter what but additional settings may could be added made in optional/foo   eg: development.nix
{
  lib,
  pkgs,
  hostSpec,
  ...
}:
{
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = lib.mkDefault (hostSpec.userFullName or hostSpec.username);
    userEmail = lib.mkDefault (
      if hostSpec ? email && hostSpec.email ? user then
        hostSpec.email.user
      else
        "${hostSpec.username}@${hostSpec.domain or "localhost"}"
    );

    ignores = [
      ".csvignore"
      # nix
      "*.drv"
      "result"
      # python
      "*.py?"
      "__pycache__/"
      ".venv/"
      # direnv
      ".direnv"
    ];
  };

}
