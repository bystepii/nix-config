{ config, ... }:
{
  fileSystems."${config.hostSpec.home}/D" = {
    device = "/dev/disk/by-uuid/4E71CDF309EFC4DC";
    fsType = "ntfs3";
    options = [
      "defaults"
      "rw"
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=15s"
      # NOTE: uid and gid must be hardcoded because dynamic references to
      # config.users.users from within a fileSystems definition cause infinite
      # recursion in the NixOS module system.
      # TODO: Revisit if NixOS ever breaks the recursion between users.users and
      # fileSystems, allowing us to use config.users.users.<name>.uid again.
      "uid=1000"
      "gid=100"
      "umask=000"
      "dmask=077"
      "fmask=077"
      "windows_names"
    ];
  };
}
