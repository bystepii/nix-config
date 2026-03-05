#############################################################
#
#  Genoa - Laptop
#  NixOS running on Lenovo Thinkpad E15
#
###############################################################

{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    #
    # ========== Hardware ==========
    #
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }

    # FIXME: Seems this is still needed for Fn keys to work?
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e15-intel

    #
    # ========== Modules ==========
    #
    (lib.custom.scanPaths ./.) # Load all host-specific *.nix files

    (map lib.custom.relativeToRoot (
      # ========== Required modules==========
      [
        "hosts/common/core"
      ]
      ++
        # ========== Optional common modules ==========
        (map (f: "hosts/common/optional/${f}") [
          # Desktop environment
          "niri.nix"

          # Services
          "services/bluetooth.nix" # bluetooth, blueman and bluez via wireplumber
          "services/openssh.nix" # allow remote SSH access
          "services/printing.nix" # CUPS

          # Network Mgmt and
          "nfs-ghost-mediashare.nix" # mount the ghost mediashare

          # Misc
          "audio.nix" # pipewire and cli controls
          "gaming.nix" # window manager
          "fonts.nix" # fonts
          "nvtop.nix" # GPU monitor (not available in home-manager)
          "obsidian.nix" # wiki
          "plymouth.nix" # boot graphics
          "protonvpn.nix" # vpn
          "thunar.nix" # gui file manager
          "wayland.nix" # wayland components and pkgs not available in home-manager
          "vlc.nix" # media player
          "yubikey.nix" # yubikey related packages and configs
        ])
    ))
  ];

  system.impermanence = {
    enable = config.hostSpec.isImpermanent;
    autoPersistHomes = true;
  };

  introdus.services = {
    silent-sddm.enable = true;
  };

  boot.initrd = {
    systemd.enable = true;
    kernelModules = [
    ];
  };
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

  services.backup = {
    enable = true;
    borgBackupStartTime = "00:10:00";

    borgServer = "${config.hostSpec.networking.subnets.grove.hosts.moth.ip}";
    borgUser = "${config.hostSpec.primaryUsername}";
    borgPort = "${toString config.hostSpec.networking.ports.tcp.moth}";

    borgRemotePath = "/run/current-system/sw/bin/borg";

    borgBackupPath = "/mnt/storage/backup/${config.hostSpec.primaryUsername}";
    borgNotifyFrom = "${config.hostSpec.email.notifier}";
    borgNotifyTo = "${config.hostSpec.email.backup}";

    borgExcludes = [
      "${config.hostSpec.home}/.local/share/Steam"
    ];
  };

  #Firmwareupdater
  #  $ fwupdmgr update
  services.fwupd.enable = true;
}
