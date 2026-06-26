{ ... }:
{
  # mount immich library from raspberrypi
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;

  fileSystems."/home/stepii/immich-app/data/library" = {
    device = "raspberrypi.home:/home/stepii/immich-app/data/library";
    fsType = "nfs";
    options = [
      "noatime"
      "noauto"
      "x-systemd.automount"
      "nofail"
      "soft"
      "timeo=5"
      "retrans=3"
      "x-systemd.mount-timeout=2s"
      "x-systemd.idle-timeout=600"
    ];
  };
}
