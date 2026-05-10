{ ... }:
{
  # mount nfs shares from stepan-laptop
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true; # needed for NFS

  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime";
      };
      what = "stepan-laptop.home:/home/stepii";
      where = "/home/stepii/laptop";
    }
  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/home/stepii/laptop";
    }
  ];

  # Ensure the mountpoint directory exists before the automount tries to use it.
  systemd.tmpfiles.rules = [
    "d /home/stepii/laptop 0755 stepii users -"
  ];
}
