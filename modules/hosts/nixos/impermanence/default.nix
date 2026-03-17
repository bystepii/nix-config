{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.system.impermanence;
  useLuks =
    config ? system
    && config.system ? disks
    && config.system.disks ? useLuks
    && config.system.disks.useLuks;
  primaryDisk =
    if (config ? system && config.system ? disks && config.system.disks ? primary) then
      config.system.disks.primary
    else
      null;
  mkRootPartitionPath =
    disk:
    if lib.hasPrefix "/dev/disk/by-" disk then
      "${disk}-part2"
    else if builtins.match ".*[0-9]$" disk != null then
      "${disk}p2"
    else
      "${disk}2";
  inferredRootDevice =
    if useLuks then
      "/dev/mapper/cryptprimary"
    else if primaryDisk != null then
      mkRootPartitionPath primaryDisk
    else
      "/dev/vda2";
  rootDeviceUnit =
    "dev-"
    + (
      lib.removePrefix "/dev/" cfg.rootDevice
      |> lib.replaceStrings [ "/" ] [ "-" ]
      |> lib.replaceStrings [ "-" ] [ "\\x2d" ]
    )
    + ".device";

  btrfsDiff = pkgs.writeShellApplication {
    name = "btrfs-diff";
    runtimeInputs = [
      pkgs.btrfs-progs
      pkgs.eza
      pkgs.fd
    ];
    text = ''
      export BTRFS_VOL="${cfg.rootDevice}"
      ${lib.readFile ./btrfs-diff.sh}
    '';
  };
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  options.system.impermanence = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.hostSpec.isImpermanent;
      description = "Enable impermanence";
    };
    removeTmpFilesOlderThan = lib.mkOption {
      type = lib.types.int;
      default = 14;
      description = "Number of days to keep old root snapshots";
    };
    autoPersistHomes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically persist the primary user's home directory";
    };
    rootDevice = lib.mkOption {
      type = lib.types.str;
      default = inferredRootDevice;
      description = "Block device mounted by initrd rollback service for btrfs subvolumes";
    };
  };

  options.environment.persist = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Additional directories persisted by impermanence";
  };

  config = lib.mkIf cfg.enable {
    boot.initrd = {
      supportedFilesystems = [ "btrfs" ];
      systemd.services.btrfs-rollback = {
        description = "Rollback BTRFS root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        wants =
          if useLuks then
            [
              "dev-mapper-cryptprimary.device"
              "systemd-cryptsetup@cryptprimary.service"
            ]
          else
            [ rootDeviceUnit ];
        after =
          if useLuks then
            [
              "dev-mapper-cryptprimary.device"
              "systemd-cryptsetup@cryptprimary.service"
            ]
          else
            [ rootDeviceUnit ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig = {
          Type = "oneshot";
          Environment = [
            "ROOT_DEVICE=${cfg.rootDevice}"
            "OLD_ROOT_RETENTION_DAYS=${toString cfg.removeTmpFilesOlderThan}"
          ];
        };
        script = lib.readFile ./btrfs-wipe-root.sh;
      };
    };

    fileSystems."${config.hostSpec.persistFolder}".neededForBoot = true;

    environment.persistence."${config.hostSpec.persistFolder}" = {
      hideMounts = true;
      directories = lib.flatten [
        [
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/etc/NetworkManager/system-connections"
          {
            directory = "/var/lib/private";
            mode = "0700";
          }
          {
            directory = "/var/cache/private";
            mode = "0700";
          }
        ]
        (lib.optional cfg.autoPersistHomes {
          directory = config.hostSpec.home;
          user = config.hostSpec.username;
          group = if pkgs.stdenv.isDarwin then "staff" else "users";
          mode = "u=rwx,g=,o=";
        })
        (builtins.attrValues config.environment.persist)
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/root/.ssh/known_hosts"
      ];
    };

    programs.fuse.userAllowOther = true;
    environment.systemPackages = [ btrfsDiff ];
  };
}
