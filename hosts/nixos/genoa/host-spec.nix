{ inputs, lib, ... }:
{
  hostSpec = {
    hostName = "genoa";
    users = lib.mkForce [
      "ta"
    ];

    isImpermanent = lib.mkForce true;
    persistFolder = "/persist";

    # System type flags
    isAdmin = lib.mkForce true;
    isDevelopment = lib.mkForce true;
    isIntrodusDev = lib.mkForce false;
    isProduction = lib.mkForce true;
    isRemote = lib.mkForce false;
    isRoaming = lib.mkForce true;

    # Functionality
    useYubikey = lib.mkForce true;
    useNeovimTerminal = lib.mkForce true;

    # Graphical
    defaultDesktop = "niri";
    # defaultDesktop = "niri-uwsm";
    theme = lib.mkForce "darcula";
    wallpaper = "${inputs.nix-assets}/images/wallpapers/zen-02.jpg";
    isAutoStyled = lib.mkForce true;
    hdr = lib.mkForce true;
  };
}
