# Host-level sops configuration. See home/<user>/common/optional/sops.nix for
# user-level secrets.
{
  inputs,
  config,
  ...
}:
let
  sopsRoot = builtins.toString inputs.nix-secrets;
  hostSecretsFile = "${sopsRoot}/sops/${config.hostSpec.hostName}.yaml";
  sharedSecretsFile = "${sopsRoot}/sops/shared.yaml";
  hasSharedSecrets = builtins.pathExists sharedSecretsFile;
  # Prefer shared passwords in complex secrets layouts; keep host-file fallback
  # for migration and recovery compatibility.
  passwordSecretsFile = if hasSharedSecrets then sharedSecretsFile else hostSecretsFile;

  hostSshKeyPath =
    if (config ? system && config.system ? impermanence && config.system.impermanence.enable) then
      "${config.hostSpec.persistFolder}/etc/ssh/ssh_host_ed25519_key"
    else
      "/etc/ssh/ssh_host_ed25519_key";
in
{
  # Import for sops-nix is handled in hosts/common/core/default.nix based on platform.

  sops = {
    defaultSopsFile = hostSecretsFile;
    validateSopsFiles = false;
    age = {
      # automatically import host SSH keys as age keys
      sshKeyPaths = [ hostSshKeyPath ];
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
  sops.secrets = {
    # These age keys are are unique for the user on each host and are generated on their own
    # (i.e. they are not derived from an ssh key).
    "keys/age" = {
      owner = config.users.users.${config.hostSpec.primaryUsername}.name;
      inherit (config.users.users.${config.hostSpec.primaryUsername}) group;
      # We need to ensure the entire directory structure is that of the user...
      path = "${config.hostSpec.home}/.config/sops/age/keys.txt";
      sopsFile = hostSecretsFile;
    };

    # Decrypt password hash for user creation. Prefer shared.yaml in complex scheme,
    # but fall back to host file for migration/recovery scenarios.
    "passwords/${config.hostSpec.primaryUsername}" = {
      sopsFile = passwordSecretsFile;
      neededForUsers = true;
    };
  };
  # The containing folders are created as root and if this is the first ~/.config/ entry,
  # the ownership is busted and home-manager can't target because it can't write into .config...
  # In the future this may not be needed, depending on how https://github.com/Mic92/sops-nix/issues/381 is fixed
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
