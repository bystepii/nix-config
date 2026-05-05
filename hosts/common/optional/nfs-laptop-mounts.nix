{ ... }:
{
  # mount nfs shares from stepan-laptop
  boot.supportedFilesystems = [ "nfs" ];

  fileSystems."/home/stepii/laptop" = {
    device = "stepan-laptop.home:/home/stepii";
    fsType = "nfs";
    options = [
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.mount-timeout=1"
    ];
  };

  fileSystems."/home/stepii/laptop/C" = {
    device = "stepan-laptop.home:/home/stepii/C";
    fsType = "nfs";
    options = [
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.mount-timeout=1"
    ];
  };

  fileSystems."/home/stepii/laptop/D" = {
    device = "stepan-laptop.home:/home/stepii/D";
    fsType = "nfs";
    options = [
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.mount-timeout=1"
    ];
  };

  # Create the base mountpoint directory. C and D will be provided by the first mount.
  systemd.tmpfiles.rules = [
    "d /home/stepii/laptop 0755 stepii users -"
  ];
}
