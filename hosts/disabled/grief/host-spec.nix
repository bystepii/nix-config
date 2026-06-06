{ lib, ... }:
{
  hostSpec = {
    hostName = "grief";
    primaryUsername = lib.mkForce "ta";

    # System type flags
    isWork = lib.mkForce false;
    isProduction = lib.mkForce false;
    isRemote = lib.mkForce true;

    # Functionality
    useYubikey = lib.mkForce true;

    isAutoStyled = lib.mkForce true;
  };
}
