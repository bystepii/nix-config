{ lib, ... }:
{
  hostSpec = {
    hostName = "guppy";
    primaryUsername = lib.mkForce "ta";

    # System type flags
    isWork = lib.mkForce false;
    isProduction = lib.mkForce false;
    isRemote = lib.mkForce true;

    # Functionality
    useYubikey = lib.mkForce true;

    # Graphical
    isAutoStyled = lib.mkForce true;
  };
}
