{
  config,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}:
{
  imports = lib.flatten [
    #
    # ========== Hardware ==========
    #
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }

    (import "${inputs.nixos-hardware}/common/cpu/amd/default.nix")
    (import "${inputs.nixos-hardware}/common/pc/ssd/default.nix")
    (import "${inputs.nixos-hardware}/common/pc/default.nix")
    (import "${inputs.nixos-hardware}/common/gpu/nvidia/ampere/default.nix")

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
        "luks-fido2.nix" # unlock LUKS with FIDO2 token (YubiKey)

        # VPN
        # "wireguard-client.nix"

        # Desktop
        "fonts.nix"

        # NFS mounts
        "nfs-laptop-mounts.nix"
        "nfs-immich-mounts.nix"

        # GPU / Gaming
        "nvidia.nix"
        "gaming-nvidia.nix"

        # Containerization
        "docker.nix"

        # Virtualization
        "libvirt.nix"

        # Desktop tools
        "polkit-agent.nix" # graphical polkit authentication agent

        # Disk tools
        "gparted.nix" # graphical disk partition editor

        # Wine
        "wine.nix"
      ])
    ))
  ];

  # GPG agent - makes YubiKey OpenPGP keys available via ssh-agent
  # TODO: maybe move this to some module
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;
  programs.gnupg.agent.enableExtraSocket = true;

  # Enable FIDO2 unlock for the primary LUKS volume using YubiKey (PIN required)
  luksFido2.enable = true;

  # Enable boltclt
  services.hardware.bolt.enable = true;

  introdus.niri.enable = true;
  introdus.services.silent-sddm.enable = true;
  services.displayManager.sddm.wayland.enable = lib.mkForce true;
  introdus.services.audio.enable = true;

  # Required for graphical session
  hardware.graphics.enable = true;

  # NVIDIA 595.71.05 (26.05 stable) fails on Linux 7.2 (strncpy removed from
  # <linux/string.h>). Pin 610.57.04 (hashes from nixpkgs master) until
  # nixos-26.05 backports a fixed driver. Same pattern as hosts/nixos/jade.
  hardware.nvidia.package = lib.mkForce (
    config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "610.57.04";
      sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
      sha256_aarch64 = "sha256-QCefrMBCmpOwuOyXv1k5Gj0iB2CYlPgnG3JToUw/j54=";
      openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
      settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
      persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
    }
  );

  # Set early framebuffer resolution for all monitors
  boot.kernelParams = lib.map (
    m: "video=${m.name}:${lib.toString m.width}x${lib.toString m.height}@${lib.toString m.refreshRate}"
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

  environment.persistence."${config.hostSpec.persistFolder}".directories = [
    "/var/lib/sbctl" # Secure Boot keys (required with impermanence)
    "/var/lib/boltd" # Thunderbolt device authorization database
  ];

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

  # Wake-on-LAN: interface name stored in nix-secrets
  networking.interfaces.${secrets.networking.hosts.onyx.primaryEthernetInterface}.wakeOnLan.enable =
    true;

  # Remote LUKS unlock via SSH in initrd
  services.remoteLuksUnlock = {
    enable = true;
    notify.enable = false;
  };

  # Remote Nix builders via ProxyJump
  services.remoteBuilder.enable = true;

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
