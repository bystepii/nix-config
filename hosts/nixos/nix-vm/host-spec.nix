{ lib, ... }:
{
  hostSpec = {
    hostName = lib.mkDefault "nix-vm";
    users = lib.mkForce [ "stepii" ];

    isImpermanent = lib.mkForce true;
    persistFolder = "/persist";

    isAdmin = lib.mkForce true;
    isDevelopment = lib.mkForce false;
    isIntrodusDev = lib.mkForce false;
    isProduction = lib.mkForce false;
    isRemote = lib.mkForce false;
    isWork = lib.mkForce false;

    useYubikey = lib.mkForce true;
    useNeovimTerminal = lib.mkForce false;

    defaultDesktop = "none";
    useWayland = false;
    hdr = lib.mkForce false;
    scaling = "1";
    # isAutoStyled = lib.mkForce false;
    # useWindowManager = lib.mkForce false;
  };
}
