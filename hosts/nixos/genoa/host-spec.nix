{ inputs, lib, ... }:
{
  hostSpec = {
    hostName = "genoa";
    users = lib.mkForce [
      "ta"
    ];

    persistFolder = "/persist";

    # System type flags
    isAdmin = lib.mkForce true;
    isRemote = lib.mkForce false; # not remotely managed
    isRoaming = lib.mkForce true;

    # Functionality
    useYubikey = lib.mkForce true;

    # Graphical
    defaultDesktop = "niri-uwsm";
    theme = lib.mkForce "darcula";
    wallpaper = "${inputs.nix-assets}/images/wallpapers/zen-02.jpg";
    isAutoStyled = lib.mkForce true;
    hdr = lib.mkForce true;
  };
}
