{ lib, ... }:
{
  programs.btop = {
    enable = true;
    settings = {
      #TODO(rice): set via stylix
      color_theme = lib.mkForce "dracula";
      round_corners = true;
      theme_background = true;
      vim_keys = true;
    };
  };
}
