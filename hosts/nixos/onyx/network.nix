{
  config,
  pkgs,
  lib,
  ...
}:
let
  routes = config.hostSpec.networking.hosts.onyx.staticRoutes or [ ];
in
{
  # Disable facter-generated per-interface DHCP so NetworkManager can take over
  # (this is the same pattern used by kalypso and jade)
  facter.detected.dhcp.enable = false;

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 3003 ];

  systemd.services."static-routes" = lib.optionalAttrs (routes != [ ]) {
    description = "Add static routes";
    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager.service" ];
    serviceConfig.Type = "oneshot";
    script = lib.concatMapStringsSep "\n" (route: ''
      until ${pkgs.iproute2}/bin/ip route get ${route.gateway} > /dev/null 2>&1; do
        sleep 1
      done
      ${pkgs.iproute2}/bin/ip route add ${route.destination} via ${route.gateway} 2>/dev/null || true
    '') routes;
  };
}
