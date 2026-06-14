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
      "soft" # return errors instead of retrying forever when laptop is off
      "timeo=5" # 0.5s per RPC attempt
      "retrans=3" # retry 3 times before giving up (~1.5s total)
      "x-systemd.mount-timeout=2s" # fail mount after 2s if laptop is unreachable
      "x-systemd.idle-timeout=600" # unmount after 600s idle (matches current behavior)
    ];
  };
}
