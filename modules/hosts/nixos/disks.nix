# Reusable disko-based disk module to avoid per-host layout duplication.
{
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.system.disks;

  btrfsContent = {
    type = "btrfs";
    extraArgs = [ "-f" ];
    subvolumes = {
      "@root" = {
        mountpoint = "/";
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
      };
      "@nix" = {
        mountpoint = "/nix";
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
      };
    }
    // (lib.optionalAttrs (config.system.impermanence.enable or false) {
      "@persist" = {
        mountpoint = config.hostSpec.persistFolder;
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
      };
    })
    // (lib.optionalAttrs (cfg.swapSize != null) {
      "@swap" = {
        mountpoint = "/.swapvol";
        swap.swapfile.size = "${toString cfg.swapSize}G";
      };
    });
  };

  luksContent = {
    type = "luks";
    name = "cryptprimary";
    passwordFile = "/tmp/disko-password";
    settings.allowDiscards = true;
    content = btrfsContent;
  };
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.system.disks = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use reusable disko templates to manage host disks";
    };
    primary = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/dev/vda";
      description = "Primary install disk";
    };
    useLuks = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use LUKS for the primary disk";
    };
    bootSize = lib.mkOption {
      type = lib.types.str;
      default = "512M";
      description = "Size of /boot partition";
    };
    swapSize = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Swap size in GiB, or null to disable swap";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.primary != null;
        message = "system.disks.enable is true but system.disks.primary is not set";
      }
    ];

    disko.devices.disk.primary = {
      type = "disk";
      device = cfg.primary;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            priority = 1;
            name = "ESP";
            size = cfg.bootSize;
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "defaults" ];
            };
          };
        }
        // {
          ${if cfg.useLuks then "luks" else "root"} = {
            size = "100%";
            content = if cfg.useLuks then luksContent else btrfsContent;
          };
        };
      };
    };
  };
}
