#############################################################
#
#  Gusto - Home Theatre
#  NixOS running on Intel N95 based mini PC
#
###############################################################

{
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
    (lib.custom.scanPaths ./.) # Load all extra host-specific *.nix files

    #
    # ========== Disk Layout ==========
    #
    inputs.disko.nixosModules.disko
    (lib.custom.relativeToRoot "hosts/common/disks/btrfs-impermanence-disk.nix")
    {
      _module.args = {
        disk = "/dev/nvme0n1";
        withSwap = true;
        swapSize = 8;
      };
    }

    #
    # ========== Modules ==========
    #
    (map lib.custom.relativeToRoot (
      # ========== Required modules ==========
      [
        "hosts/common/core"
      ]
      ++
        # ========== Optional common modules ==========
        (map (f: "hosts/common/optional/${f}") [
          # Desktop environment and login manager
          "gnome.nix"

          # Services
          "services/openssh.nix" # allow remote SSH access

          # Network Mgmt
          "nfs-ghost-mediashare.nix" # mount the ghost mediashare

          # Misc
          "audio.nix" # pipewire and cli controls
          "plymouth.nix" # boot graphics
          "fonts.nix" # fonts
          "vlc.nix" # media player
        ])
    ))
  ];

  system.impermanence = {
    enable = false;
    autoPersistHomes = true;
  };

  introdus.services = {
    silent-sddm.enable = true;
  };

  boot.initrd.systemd.enable = true;

  boot.loader.systemd-boot = {
    enable = true;
    # When using plymouth, initrd can expand by a lot each time, so limit how
    # many we keep around
    configurationLimit = lib.mkDefault 10;
    consoleMode = "max";
  };
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # ========== Auto-login as regular user ==========
  services.displayManager.autoLogin = {
    enable = lib.mkForce true;
    user = lib.mkForce "media";
  };
  services.displayManager.sddm.autoLogin = {
    relogin = true;
  };

  # ========== autosshTunnel ==========
  tunnels.cakes.enable = true;
}
