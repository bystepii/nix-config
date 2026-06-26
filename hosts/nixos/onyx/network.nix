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

  # Initrd: do DHCPv4 so remote LUKS unlock can work over IPv4, but
  # flush the initrd's IP state on switch_root so the real root's
  # NetworkManager starts with a clean interface and runs DHCPv4
  # unconditionally. Without KeepConfiguration=no, NM sees the
  # initrd's "no lease" state and creates a profile with
  # ipv4.method=disabled, forcing a manual `nmcli device modify
  # enp6s0 ipv4.method auto` after every boot.
  boot.initrd.systemd.network.networks."10-eth-dhcp" = {
    matchConfig = {
      Type = "ether";
    };
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = true;
      KeepConfiguration = "no";
    };
    dhcpV4Config = {
      UseDNS = true;
    };
  };

  systemd.services."static-routes" = lib.optionalAttrs (routes != [ ]) {
    description = "Add static routes";
    after = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    script = lib.concatMapStringsSep "\n" (route: ''
      ${pkgs.iproute2}/bin/ip route get ${route.gateway} > /dev/null 2>&1 || exit 0
      ${pkgs.iproute2}/bin/ip route add ${route.destination} via ${route.gateway} 2>/dev/null || true
    '') routes;
  };

  systemd.timers."static-routes" = lib.optionalAttrs (routes != [ ]) {
    description = "Try to add static routes once network is up";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      Unit = "static-routes.service";
    };
  };
}
