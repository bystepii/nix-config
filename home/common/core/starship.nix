{
  pkgs,
  lib,
  ...
}:
{
  # Disabled in favor of powerlevel10k
  programs.starship = {
    enable = lib.mkForce false;
    package = pkgs.unstable.starship;
  };
}
