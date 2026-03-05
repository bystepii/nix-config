{ lib, ... }:
{
  hostSpec = {
    hostName = "ghost";
    users = lib.mkForce [
      "ta"
    ];

    isImpermanent = lib.mkForce true;
    persistFolder = "/persist";

    # System type flags
    isAdmin = lib.mkForce true;
    isWork = lib.mkForce false;
    isProduction = lib.mkForce true;
    isRemote = lib.mkForce true;

    # Functionality
    useYubikey = lib.mkForce true;

    # Graphical
    defaultDesktop = "niri";
    hdr = lib.mkForce true;
    scaling = "2";
    isAutoStyled = lib.mkForce true;
    #FIXME: not in stylix yet
    #theme = lib.mkForce "ascendancy";
    #wallpaper = ""; # use default since it's overridden by wallpaperDir option for swww settings in home/ta/ghost.nix
  };
}
