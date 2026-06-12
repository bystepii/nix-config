{
  lib,
  config,
  pkgs,
  ...
}:
{
  services.nfs.server = {
    enable = true;
    exports = ''
      ${config.hostSpec.home}    stepan-desktop.home(rw,sync,root_squash,no_subtree_check)
      ${config.hostSpec.home}/D  stepan-desktop.home(rw,sync,root_squash,no_subtree_check)
    '';
  };

  # NFSv4-only: open the server port on all interfaces
  networking.firewall.allowedTCPPorts = [ 2049 ];

  # Persist NFS server state for impermanence
  environment.persistence = lib.mkIf config.hostSpec.isImpermanent {
    "${config.hostSpec.persistFolder}".directories = [
      "/var/lib/nfs"
    ];
  };

  # Re-export NFS after DNS is ready. If the client hostname doesn't resolve
  # (e.g. away from home), skip gracefully — no error, no retry.
  systemd.services.nfs-reexport-after-dns = {
    description = "Re-export NFS after DNS is ready";
    after = [
      "network-online.target"
      "nss-lookup.target"
      "nfs-server.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      if /run/current-system/sw/bin/timeout 5 /run/current-system/sw/bin/getent hosts stepan-desktop.home > /dev/null; then
        ${pkgs.nfs-utils}/bin/exportfs -r
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };
}
