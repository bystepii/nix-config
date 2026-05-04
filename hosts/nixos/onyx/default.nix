{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    #
    # ========== Hardware ==========
    #
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }

    # Secure Boot via lanzaboote
    inputs.lanzaboote.nixosModules.lanzaboote

    #
    # ========== Modules ==========
    #
    (lib.custom.scanPaths ./.)

    (map lib.custom.relativeToRoot (
      # ========== Required modules==========
      [
        "hosts/common/core"
      ]
      # ========== Optional common modules ==========
      ++ (map (f: "hosts/common/optional/${f}") [
        # Services
        "services/openssh.nix" # allow remote SSH access
        "yubikey.nix" # yubikey related packages and configs

        # Desktop
        "fonts.nix"
      ])
    ))
  ];

  # GPG agent - makes YubiKey OpenPGP keys available via ssh-agent
  # TODO: maybe move this to some module
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;
  programs.gnupg.agent.enableExtraSocket = true;

  introdus.niri.enable = true;
  introdus.services.silent-sddm.enable = true;
  introdus.services.audio.enable = true;

  # Required for graphical session
  hardware.graphics.enable = true;

  # Set early framebuffer resolution for all monitors
  boot.kernelParams = lib.map (
    m: "video=${m.name}:${toString m.width}x${toString m.height}@${toString m.refreshRate}"
  ) config.monitors;

  # Secure Boot with lanzaboote (replaces systemd-boot)
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";

    # Automatic Secure Boot key generation and enrollment
    autoGenerateKeys.enable = true;
    autoEnrollKeys = {
      enable = true;
      # Include Microsoft keys for Windows/Ubuntu dual-boot compatibility
      includeMicrosoftKeys = true;
      # Automatically reboot after enrollment preparation
      autoReboot = true;
    };
  };

  environment.systemPackages = [ pkgs.sbctl ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 5;

  boot.initrd = {
    systemd.enable = true;
    kernelModules = [
      "xhci_pci"
      "ohci_pci"
      "ehci_pci"
      "ahci"
      "usbhid"
      "sr_mod"
    ];
    # luks.forceLuksSupportInInitrd = true;
  };

  # boot.kernelParams = [
  #   "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"
  # ];

  # fileSystems."/boot".options = [ "umask=0077" ];

  # environment.systemPackages = lib.attrValues {
  #   inherit (pkgs)
  #     wget
  #     curl
  #     rsync
  #     git
  #     ;
  # };
}
