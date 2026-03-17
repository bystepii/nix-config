{
  inputs,
  system,
  pkgs,
  lib,
  formatter,
  ...
}:
let
  introdusLib = inputs.introdus.lib.mkIntrodusLib { inherit lib; };
in
{
  bats-test =
    pkgs.runCommand "bats-test"
      {
        src = ../.;
        buildInputs = builtins.attrValues {
          inherit (pkgs)
            bats
            yq-go
            inetutils
            sops
            age
            ripgrep
            ;
        };
      }
      ''
        cd $src
        bats tests
        touch $out
      '';

  pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
    src = ../.;
    default_stages = [ "pre-commit" ];
    hooks = lib.recursiveUpdate (introdusLib.checks.mkPreCommitHooks pkgs formatter) {
      check-added-large-files = {
        enable = true;
        excludes = [
          "\\.png"
          "\\.jpg"
        ];
      };
      check-case-conflicts.enable = true;
      check-executables-have-shebangs.enable = true;
      check-shebang-scripts-are-executable.enable = false;
      check-merge-conflicts.enable = true;
      detect-private-keys.enable = true;
      fix-byte-order-marker.enable = true;
      mixed-line-endings.enable = true;
      trim-trailing-whitespace.enable = true;

      forbid-submodules = {
        enable = true;
        name = "forbid submodules";
        description = "forbids any submodules in the repository";
        language = "fail";
        entry = "submodules are not allowed in this repository:";
        types = [ "directory" ];
      };

      destroyed-symlinks = {
        enable = true;
        name = "destroyed-symlinks";
        description = "detects symlinks changed into regular path text files.";
        package = inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks;
        entry = "${inputs.pre-commit-hooks.checks.${system}.pre-commit-hooks}/bin/destroyed-symlinks";
        types = [ "symlink" ];
      };

      nixfmt-rfc-style.enable = true;
      deadnix = {
        enable = true;
        settings.noLambdaArg = true;
      };

      shfmt.enable = true;
      shellcheck.enable = true;
      end-of-file-fixer.enable = true;
    };
  };
}
