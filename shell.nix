# Shell for bootstrapping flake-enabled nix and other tooling
{
  pkgs,
  checks,
  lib,
  ...
}:
{
  default = pkgs.mkShell {
    # Nix utility settings
    NIX_CONFIG = "extra-experimental-features = nix-command flakes pipe-operators";
    NIXPKGS_ALLOW_BROKEN = "1";

    # Bootstrap script settings
    BOOTSTRAP_USER = "stepii";
    BOOTSTRAP_SSH_PORT = "22";
    BOOTSTRAP_SSH_KEY = "~/.ssh/id_manu";

    # This is needed in case we manually run scripts or bats tests directly.
    HELPERS_PATH = "${pkgs.introdus.introdus-helpers}/share/introdus-helpers/helpers.sh";

    buildInputs = checks.pre-commit-check.enabledPackages;
    nativeBuildInputs =
      lib.attrValues {
        inherit (pkgs)
          nix
          nixos-rebuild
          home-manager
          git
          just
          pre-commit
          deadnix
          statix
          git-crypt
          attic-client
          nh
          sops
          yq-go
          bats
          age
          ssh-to-age
          gum
          ;
        inherit (pkgs.introdus)
          bootstrap-nixos
          check-sops
          ;
      }
      ++ [
        (pkgs.introdus.rebuild-host.overrideAttrs (_: {
          perHostLocks = false;
        }))
        pkgs.unstable.nixVersions.git
      ];

    shellHook = ''
      if [ -z "''${NIX_SECRETS_DIR:-}" ]; then
        export NIX_SECRETS_DIR="$(git rev-parse --show-toplevel)/../nix-secrets"
      fi
    ''
    + checks.pre-commit-check.shellHook;
  };
}
