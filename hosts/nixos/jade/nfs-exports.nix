{ lib, config, ... }:
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
}
