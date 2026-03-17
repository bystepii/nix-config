# home level sops. see hosts/common/optional/sops.nix for hosts level info and instructions
{
  inputs,
  config,
  osConfig,
  lib,
  ...
}:
let
  sopsFolder = (builtins.toString inputs.nix-secrets) + "/sops";
  homeDirectory = config.home.homeDirectory;

  yubikeyNames =
    if osConfig ? yubikey && osConfig.yubikey ? identifiers then
      builtins.attrNames osConfig.yubikey.identifiers
    else
      [ ];

  extractYubikeySshSecrets =
    osConfig ? yubikey && osConfig.yubikey ? extractSshSecrets && osConfig.yubikey.extractSshSecrets;

  yubikeySecrets = lib.optionalAttrs osConfig.hostSpec.useYubikey (
    {
      # Default pam-u2f authfile location used by the host-level yubikey module.
      "keys/u2f" = {
        sopsFile = "${sopsFolder}/shared.yaml";
        path = "${homeDirectory}/.config/Yubico/u2f_keys";
      };
    }
    // lib.optionalAttrs (extractYubikeySshSecrets && yubikeyNames != [ ]) (
      lib.attrsets.mergeAttrsList (
        lib.lists.map (name: {
          "keys/ssh/${name}" = {
            sopsFile = "${sopsFolder}/shared.yaml";
            path = "${homeDirectory}/.ssh/id_${name}";
          };
        }) yubikeyNames
      )
    )
  );
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];
  sops = {
    # Host-level activation writes the user age key here for home-manager decryption.
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = "${sopsFolder}/${osConfig.hostSpec.hostName}.yaml";
    validateSopsFiles = false;

    secrets = { } // yubikeySecrets;
  };
}
