{ ... }:
{
  # mount nfs shares from stepan-laptop
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true; # needed for NFS

  fileSystems."/home/stepii/laptop" = {
    device = "stepan-laptop.home:/home/stepii";
    fsType = "nfs";
    options = [
      "noatime"
      "noauto" # don't mount at boot
      "x-systemd.automount" # create automount unit
      "nofail" # don't fail activation if mount fails
      "x-systemd.device-timeout=5s" # limit hang time when laptop is off
      "x-systemd.idle-timeout=600" # unmount after 600s idle (matches current behavior)
    ];
  };
}
