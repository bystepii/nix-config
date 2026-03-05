# hosts level sops. see home/[user]/common/optional/sops.nix for home/user level
{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  sopsFolder = toString inputs.nix-secrets + "/sops";
in
{
  #the import for inputs.sops-nix.nixosModules.sops is handled in hosts/common/core/default.nix so that it can be dynamically input according to the platform

  sops = {
    #    defaultSopsFile = "${secretsFile}";
    defaultSopsFile = "${sopsFolder}/${config.hostSpec.hostName}.yaml";
    validateSopsFiles = false;
    age = {
      # automatically import host SSH keys as age keys
      sshKeyPaths = [ "${config.hostSpec.persistFolder}/etc/ssh/ssh_host_ed25519_key" ];
    };
    # secrets will be output to /run/secrets
    # e.g. /run/secrets/msmtp-password
    # secrets required for user creation are handled in respective ./users/<username>.nix files
    # because they will be output to /run/secrets-for-users and only when the user is assigned to a host.
  };

  # For home-manager a separate age key is used to decrypt secrets and must be placed onto the host. This is because
  # the user doesn't have read permission for the ssh service private key. However, we can bootstrap the age key from
  # the secrets decrypted by the host key, which allows home-manager secrets to work without manually copying over
  # the age key.
  sops.secrets =
    let
      linuxEntries = lib.mergeAttrsList (
        map (user: {
          "passwords/${user}" = {
            sopsFile = "${sopsFolder}/shared.yaml";
            neededForUsers = true;
          };
        }) config.hostSpec.users
      );
    in
    lib.mkMerge [
      {
        # FIXME: We may need an age key per user technically?
        "keys/age" = {
          owner = config.users.users.${config.hostSpec.primaryUsername}.name;
          group =
            if pkgs.stdenv.isLinux then
              config.users.users.${config.hostSpec.primaryUsername}.group
            else
              "staff";
          # See later activation script for folder permission sanitization
          path = "${config.hostSpec.home}/.config/sops/age/keys.txt";
        };

        # NOTE: This entry is duplicated in home sops and here because nix.nix can't
        # directly check for sops usage due to recursion in some situations
        # formatted as extra-access-tokens = github.com=<PAT token>
        "tokens/nix-access-tokens" = {
          sopsFile = "${sopsFolder}/shared.yaml";
        };

        "passwords/msmtp" = {
          sopsFile = "${sopsFolder}/shared.yaml";
        };
      }
      # only reference borg password if host is using backup
      (lib.mkIf config.services.backup.enable {
        "passwords/borg" = {
          owner = "root";
          group = if pkgs.stdenv.isLinux then "root" else "wheel";
          mode = "0600";
          path = "/etc/borg/passphrase";
        };
      })
      (lib.mkIf pkgs.stdenv.isLinux linuxEntries)
    ];
  # The containing folders are created as root and if this is the first ~/.config/ entry,
  # the ownership is busted and home-manager can't target because it can't write into .config...
  # FIXME(sops): We might not need this depending on how https://github.com/Mic92/sops-nix/issues/381 is fixed
  system.activationScripts.sopsSetAgeKeyOwnership =
    let
      ageFolder = "${config.hostSpec.home}/.config/sops/age";
      user = config.users.users.${config.hostSpec.primaryUsername}.name;
      group = config.users.users.${config.hostSpec.primaryUsername}.group;
    in
    ''
      mkdir -p ${ageFolder} || true
      chown -R ${user}:${group} ${config.hostSpec.home}/.config
    '';
}
