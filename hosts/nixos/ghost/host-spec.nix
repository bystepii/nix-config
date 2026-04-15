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
    isDevelopment = lib.mkForce true;
    isIntrodusDev = lib.mkForce true;
    isProduction = lib.mkForce true;
    isRemote = lib.mkForce false;
    isWork = lib.mkForce false;

    # Functionality
    useYubikey = lib.mkForce true;
    useNeovimTerminal = lib.mkForce true;

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
