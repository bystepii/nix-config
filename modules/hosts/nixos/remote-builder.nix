# Remote Nix builder support with ProxyJump and dedicated SSH key
#
# This module deploys a dedicated SSH keypair (via SOPS) for root to use
# when connecting to remote Nix builders. The key is separate from user
# YubiKey auth because root cannot access the user's GPG agent socket.
#
# Builder hosts are configured in nix-secrets/nix/builders.nix and accessed
# via secrets.builders.
#
# Setup:
#   1. Generate keypair: ssh-keygen -t ed25519 -f /tmp/nix-builder-key -N ""
#   2. Add private key to nix-secrets/sops/shared.yaml as keys/ssh/builder
#   3. Add public key to nix-secrets/sops/shared.yaml as keys/ssh/builder_pub
#   4. Add public key to compute hosts: ~/.ssh/authorized_keys
#   5. Enable: services.remoteBuilder.enable = true;
{
  config,
  lib,
  inputs,
  secrets,
  ...
}:
let
  cfg = config.services.remoteBuilder;
  builders = secrets.builders;
  rootHome = "/root";
  builderKey = "${rootHome}/.ssh/id_builder";
  sopsFolder = lib.toString inputs.nix-secrets + "/sops";

  # Build SSH config entries dynamically from secrets
  # The proxy1 entry gives the ProxyJump subprocess the builder key.
  # The per-host entries set ProxyJump and User.
  sshConfigEntries = [
    ''
      Host ${builders.proxyJump}
        IdentityFile ${builderKey}
        IdentitiesOnly yes
    ''
  ]
  ++ (map (b: ''
    Host ${b.hostname}
      ProxyJump ${builders.proxyUser}@${builders.proxyJump}
      User ${b.user}
  '') builders.hosts);
in
{
  options.services.remoteBuilder = {
    enable = lib.mkEnableOption "Remote Nix builder support";
  };

  config = lib.mkIf cfg.enable {
    # Deploy SSH keypair to root via SOPS
    sops.secrets."keys/ssh/builder" = {
      sopsFile = "${sopsFolder}/shared.yaml";
      owner = "root";
      group = "root";
      path = builderKey;
    };
    sops.secrets."keys/ssh/builder_pub" = {
      sopsFile = "${sopsFolder}/shared.yaml";
      owner = "root";
      group = "root";
      path = "${builderKey}.pub";
    };

    # SSH config for builder hosts (generated from secrets)
    # Uses programs.ssh.extraConfig to merge into NixOS-generated /etc/ssh/ssh_config
    # (ssh_config.d/ is NOT included by NixOS's generated config)
    programs.ssh.extraConfig = lib.concatStringsSep "\n" sshConfigEntries;

    # Nix remote builder configuration (generated from secrets)
    nix = {
      distributedBuilds = true;
      settings.builders-use-substitutes = true;
      buildMachines = map (b: {
        hostName = b.hostname;
        sshUser = b.user;
        sshKey = builderKey;
        protocol = "ssh-ng";
        system = "x86_64-linux";
        maxJobs = b.threads;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }) builders.hosts;
    };
  };
}
