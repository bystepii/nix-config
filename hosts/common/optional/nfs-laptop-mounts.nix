{ ... }:
{
  # mount nfs shares from stepan-laptop
  boot.supportedFilesystems = [ "nfs" ];
  fileSystems."/home/stepii/laptop" = {
    device = "stepan-laptop.home:/home/stepii";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "nofail"
      "x-systemd.device-timeout=15s"
      "x-systemd.idle-timeout=600"
    ];
  };

  # Ensure the mountpoint directory exists before the automount tries to use it.
  systemd.tmpfiles.rules = [
    "d /home/stepii/laptop 0755 stepii users -"
  ];
}
