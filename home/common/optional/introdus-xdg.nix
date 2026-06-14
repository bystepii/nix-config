{
  introdus.xdg = {
    enable = true;
    csvAssociations = [
      "libreoffice-calc.desktop"
      "nvim.desktop"
    ];
  };

  xdg.portal = {
    config = {
      # Fix for niri screen sharing
      common.default = [ "gnome" ];
    };
  };
}
