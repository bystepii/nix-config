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

  # Re-export after DNS is ready, so that hostname-based exports resolve correctly.
  # exportfs silently ignores unresolvable hostnames and exits 0, so we must check
  # resolution ourselves and fail (triggering systemd restart) until it works.
  systemd.services.nfs-reexport-after-dns = {
    description = "Re-export NFS after DNS is ready";
    after = [
      "network-online.target"
      "nss-lookup.target"
      "nfs-server.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
    script = ''
      if ! /run/current-system/sw/bin/timeout 5 /run/current-system/sw/bin/getent hosts stepan-desktop.home > /dev/null; then
        echo "DNS not ready for stepan-desktop.home"
        exit 1
      fi
      exec ${pkgs.nfs-utils}/bin/exportfs -r
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
