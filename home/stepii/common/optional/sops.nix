# home level sops. see hosts/common/optional/sops.nix for hosts level info and instructions
{
  inputs,
  config,
  osConfig,
  ...
}:
let
  sopsFolder = (builtins.toString inputs.nix-secrets) + "/sops";
  homeDirectory = config.home.homeDirectory;
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];
  sops = {
    # Host-level activation writes the user age key here for home-manager decryption.
    age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

    defaultSopsFile = "${sopsFolder}/${osConfig.hostSpec.hostName}.yaml";
    validateSopsFiles = false;

    secrets = {
    };
  };
}
