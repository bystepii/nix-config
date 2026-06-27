{
  config,
  lib,
  secrets,
  ...
}:
let
  # Static routes for the wired connection, sourced from nix-secrets.
  # Fallback to hostSpec so the build doesn't fail if the field is
  # absent in nix-secrets. Each route is { destination; gateway; }.
  rawRoutes =
    secrets.networking.hosts.onyx.staticRoutes or config.hostSpec.networking.hosts.onyx.staticRoutes
      or [ ];

  # Build the { route1, route2, ... } attrset that NM's keyfile parser
  # expects. Each entry is "<destination>,<gateway>".
  # imap1 produces 1-indexed names (route1, route2, ...).
  routesFields = lib.listToAttrs (
    lib.imap1 (i: r: {
      name = "route${toString i}";
      value = "${r.destination},${r.gateway}";
    }) rawRoutes
  );

  primaryIface = config.hostSpec.networking.hosts.onyx.primaryEthernetInterface;
in
{
  # Disable facter-generated per-interface DHCP so NetworkManager can take over
  # (this is the same pattern used by kalypso and jade)
  facter.detected.dhcp.enable = false;

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  # Disable NetworkManager's auto-creation of default profiles.
  # Without this, NM creates a "Wired connection 1" for enp6s0 on every
  # fresh boot, which wins over our declarative "Wired" profile (race)
  # and doesn't have the static route.
  networking.networkmanager.settings.main.no-auto-default = "*";

  networking.firewall.allowedTCPPorts = [ 3003 ];

  # Initrd: DHCPv4 (state flushed on switch_root) so remote LUKS
  # unlock works over IPv4 and the real root's NM starts clean.
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

  # Declarative Wired NM connection with the static route from
  # nix-secrets. Wins over NM's auto-created default by
  # autoconnect-priority=10.
  networking.networkmanager.ensureProfiles.profiles.Wired = {
    connection = {
      id = "Wired";
      type = "ethernet";
      autoconnect = true;
      autoconnect-priority = 10;
      interface-name = primaryIface;
    };
    ethernet = { };
    ipv4 = {
      method = "auto";
    }
    // routesFields; # route1, route2, ... from nix-secrets
    ipv6 = {
      method = "auto";
    };
  };

  # Force-activate the declarative Wired profile after ensureProfiles
  # writes it. Closes the timing race where NM's auto-created
  # `Wired connection 1` activates before our profile lands.
  systemd.services."nm-activate-wired" = {
    description = "Force-activate the declarative Wired NM profile";
    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager-ensure-profiles.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    script = ''
      if nmcli -t -f NAME c show 2>/dev/null | grep -qxF 'Wired'; then
        nmcli connection up Wired || true
      fi
    '';
  };
}
