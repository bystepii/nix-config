{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "modules/common/host-spec.nix"
      "hosts/common/core/ssh.nix"
      "hosts/common/users/primary"
      "hosts/common/users/primary/nixos.nix"
      "hosts/common/optional/minimal-user.nix"
    ])
  ];

  hostSpec = {
    isMinimal = lib.mkForce true;
    username = "stepii";
  };

  fileSystems."/boot".options = [ "umask=0077" ];
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = lib.mkDefault 3;
    consoleMode = lib.mkDefault "max";
  };
  boot.initrd = {
    systemd.enable = true;
    systemd.emergencyAccess = true;
  };
  boot.kernelParams = [
    "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"
    "systemd.show_status=true"
    "systemd.log_target=console"
    "systemd.journald.forward_to_console=1"
  ];

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      wget
      curl
      rsync
      git
      ;
  };

  networking = {
    networkmanager.enable = true;
  };

  services = {
    qemuGuest.enable = true;
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings.PermitRootLogin = "yes";
      settings.PubkeyAcceptedAlgorithms = "+ssh-rsa";
      authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    };
  };

  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      warn-dirty = false;
    };
  };

  system.stateVersion = "24.11";
}
