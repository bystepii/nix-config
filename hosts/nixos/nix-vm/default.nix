{
  inputs,
  lib,
  # pkgs,
  ...
}:
{
  imports = lib.flatten [
    #
    # ========== Hardware ==========
    #
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }

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
      ])
    ))
  ];

  # GPG agent - makes YubiKey OpenPGP keys available via ssh-agent
  # TODO: maybe move this to some module
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;
  programs.gnupg.agent.enableExtraSocket = true;

  boot.loader = {
    systemd-boot = {
      enable = true;
      # When using plymouth, initrd can expand by a lot each time, so limit how many we keep around
      configurationLimit = lib.mkDefault 10;
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = true;
    timeout = 5;
  };

  boot.initrd = {
    systemd.enable = true;
    kernelModules = [
      "xhci_pci"
      "ohci_pci"
      "ehci_pci"
      "virtio_pci"
      "ahci"
      "usbhid"
      "sr_mod"
      "virtio_blk"
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
