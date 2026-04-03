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
    BOOTSTRAP_USER = "ta";
    BOOTSTRAP_SSH_PORT = "22";
    BOOTSTRAP_SSH_KEY = "~/.ssh/id_yubikey";
    NIX_SECRETS_DIR = "/home/ta/src/nix/nix-secrets";

    # This is needed in case we manually run bats tests and similar
    # FIXME: move bats test to introdus to get rid of this
    HELPERS_PATH = "${pkgs.introdus.introdus-helpers}/share/introdus-helpers/helpers.sh";

    buildInputs = checks.pre-commit-check.enabledPackages;
    nativeBuildInputs =
      # FIXME: Some of these can go away because of the helpers.sh moving and
      # becoming self-contained?
      lib.attrValues {
        inherit (pkgs)
          home-manager
          git
          just
          pre-commit
          sops
          deadnix # FIXME: deprecated?
          statix
          git-crypt # encrypt secrets in git not suited for sops
          attic-client # for attic backup

          # FIXME: Deprecated now that we use rebuild-host
          nh # fancier nix building

          # FIXME: This needs to switch to being supplied by the introdus-helpers itself
          yq-go # jq for yaml, used for build scripts

          # deprecate
          flyctl # for fly.io

          # FIXME: Move to introdus
          bats # for testing

          age # bootstrap script
          ssh-to-age # bootstrap script
          gum # shell script ricing
          ;
        inherit (pkgs.introdus)
          bootstrap-nixos # introdus script for bootstrapping new hosts
          check-sops
          json2nix
          ;
      }
      ++ [
        # introdus script for rebuilding a remote/local hosts
        # with optional per-host locking support
        (pkgs.introdus.rebuild-host.overrideAttrs (_: {
          perHostLocks = false;
        }))
        # New enough to get memory management improvements
        pkgs.unstable.nixVersions.git
      ];
    inherit (checks.pre-commit-check) shellHook;
  };
}
