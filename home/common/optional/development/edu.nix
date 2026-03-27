{ pkgs, ... }:
{
  home.packages = [ pkgs.unstable.bootdev-cli ];
}
