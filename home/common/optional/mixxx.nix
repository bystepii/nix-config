{ pkgs, ... }:
{
  home.packages = with pkgs; [
    mixxx
  ];
}
