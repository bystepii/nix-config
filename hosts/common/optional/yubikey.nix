{ ... }:
{
  hostSpec.useYubikey = true;

  yubikey = {
    enable = true;
    autoScreenLock = true;
    autoScreenUnlock = true;
    identifiers = {
      primary = 19717214;
    };
  };
}
