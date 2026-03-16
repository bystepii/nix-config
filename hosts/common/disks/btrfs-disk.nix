# `...` is needed because dikso passes diskoFile
{
  lib,
  config,
  disk ? "/dev/vda",
  withSwap ? false,
  swapSize,
  ...
}:
let
  useImpermanence =
    config ? system && config.system ? impermanence && config.system.impermanence.enable;
in
{
  disko.devices = {
    disk = {
      disk0 = {
        type = "disk";
        device = disk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
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
                // (lib.optionalAttrs useImpermanence {
                  "@persist" = {
                    mountpoint = config.hostSpec.persistFolder;
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                })
                // {
                  "@swap" = lib.mkIf withSwap {
                    mountpoint = "/.swapvol";
                    swap.swapfile.size = "${swapSize}G";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
