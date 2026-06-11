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

    networkmanager.dispatcherScripts = lib.optionals (routes != [ ]) [
      {
        type = "basic";
        source = pkgs.writeText "onyx-static-routes" ''
          IFACE=$1
          ACTION=$2
          if [ "$ACTION" = "up" ]; then
            ${lib.concatMapStringsSep "\n" (route: ''
              if ${pkgs.iproute2}/bin/ip route get ${route.gateway} > /dev/null 2>&1; then
                ${pkgs.iproute2}/bin/ip route add ${route.destination} via ${route.gateway} 2>/dev/null || true
              fi
            '') routes}
          fi
        '';
      }
    ];
  };
}
