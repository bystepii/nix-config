# Nix settings shared across hosts.
# Keep this module architecture-level and avoid personal app policy here.

{
  inputs,
  config,
  lib,
  ...
}:
let
  hasNixAccessToken =
    config ? sops && config.sops ? secrets && config.sops.secrets ? "tokens/nix-access-tokens";
in
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      # See https://jackson.dev/post/nix-reasonable-defaults/
      connect-timeout = 5;
      log-lines = 25;
      min-free = 128000000; # 128MB
      max-free = 1000000000; # 1GB

      trusted-users = [ "@wheel" ];
      auto-optimise-store = true;
      warn-dirty = false;
      allow-import-from-derivation = true;

      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
    };

    # Add each flake input as a registry entry for nix3 command consistency.
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # Add inputs to legacy nix path for command parity.
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    # Optional include for authenticated access where token secret is present.
    extraOptions =
      if hasNixAccessToken then "!include ${config.sops.secrets."tokens/nix-access-tokens".path}" else "";
  };
}
