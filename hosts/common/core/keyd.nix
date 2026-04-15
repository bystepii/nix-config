# Host-specific binds should be in hosts/<system>/<host>/default.nix
{ ... }:
{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ]; # Apply to all keyboards
      settings = {
        main = {
          capslock = "\\";
          numlock = "noop";
        };
      };
    };
  };
}
