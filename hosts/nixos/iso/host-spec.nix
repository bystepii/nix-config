{ lib, ... }:
{
  hostSpec = {
    hostName = "iso";
    primaryUsername = "stepii";
    users = [ "stepii" ];
    isProduction = lib.mkForce false;
    handle = "stepii";
    email.gitHub = "stepii@users.noreply.github.com";
  };
}
