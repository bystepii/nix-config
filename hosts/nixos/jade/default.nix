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

    (import "${inputs.nixos-hardware}/common/cpu/intel/default.nix")
    (import "${inputs.nixos-hardware}/common/cpu/intel/coffee-lake/default.nix")
    (import "${inputs.nixos-hardware}/common/gpu/nvidia/pascal/default.nix")
    (import "${inputs.nixos-hardware}/common/pc/laptop/default.nix")
    (import "${inputs.nixos-hardware}/common/pc/ssd/default.nix")
    (import "${inputs.nixos-hardware}/common/pc/laptop/hdd/default.nix")

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
        "wireguard-client.nix"

        # Desktop
        "fonts.nix"

        # NFS mounts
        # "nfs-laptop-mounts.nix"

        # GPU / Gaming
        "nvidia.nix"
        "gaming-nvidia.nix"

        # Containerization
        "docker.nix"

        # Desktop tools
        "polkit-agent.nix" # graphical polkit authentication agent
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

  # Battery services for noctalia
  batteryPowerServices.enable = true;

  # Required for graphical session
  hardware.graphics.enable = true;

  # GTX 1060 (Pascal) is not supported by 595; pin to 580
  # Using mkDriver to pin 580.173.02 — nixos-26.05 still ships 580.142
  # which doesn't compile on kernel 7.x (missing linux/of_gpio.h). Remove when
  # nixos-26.05 catches up to master's 580.173.02+.
  hardware.nvidia.package = lib.mkForce (
    config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "580.173.02";
      sha256_64bit = "sha256-jY65AB4FqaimY9PV0wT+tk7yhE7hhczf2VJ4aCD0bhs=";
      sha256_aarch64 = "sha256-1lvVYIfvTXjwSoCNp4g8NaWQHF/TfpXRUKdgLrqXqoA=";
      openSha256 = "sha256-lhloZdf6XbaAFTZBF1DxE0Nv9VC6obY8UPf0VyfVepE=";
      settingsSha256 = "sha256-dfdu/3tnwHUfP7WoeQFNOMalMlpmUWjeMDIOnu+yi8E=";
      persistencedSha256 = "sha256-j8YM1w231X+JIP3c3TpUNurEBumEu1stVjzFGWu1JXE=";
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
