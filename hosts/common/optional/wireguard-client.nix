{
  config,
  lib,
  pkgs,
  ...
}:
let
  wgCommon = config.hostSpec.networking.wireguard or { };
  wgHost = wgCommon.hosts.${config.hostSpec.hostName} or { };
  wg = lib.removeAttrs wgCommon [ "hosts" ] // wgHost;
in
lib.mkIf (wgHost != { }) {
  environment.systemPackages = [ pkgs.wireguard-tools ];

  sops.secrets."wireguard/privateKey" = { };
  sops.secrets."wireguard/presharedKey" = { };

  networking.networkmanager.ensureProfiles = {
    profiles."${wg.interfaceName}" = {
      connection = {
        id = wg.interfaceName;
        type = "wireguard";
        interface-name = wg.interfaceName;
        autoconnect = "false";
      };
      wireguard = {
        listen-port = "0";
        private-key-flags = "1"; # secret agent
      };
      ipv4 = {
        method = "manual";
        address1 = wg.clientAddress;
        dns = wg.dns;
        dns-search = "~";
      };
      ipv6 = {
        method = "manual";
        address1 = wg.clientAddress6;
        addr-gen-mode = "default";
      };
      "wireguard-peer.${wg.serverPublicKey}" = {
        endpoint = wg.serverEndpoint;
        persistent-keepalive = "25";
        allowed-ips = "${wg.allowedIPs};";
        preshared-key-flags = "1"; # secret agent
      };
    };

    secrets.entries = [
      {
        file = config.sops.secrets."wireguard/privateKey".path;
        key = "private-key";
        matchId = wg.interfaceName;
        matchSetting = "wireguard";
        matchType = "wireguard";
      }
      {
        file = config.sops.secrets."wireguard/presharedKey".path;
        key = "peers.${wg.serverPublicKey}.preshared-key";
        matchId = wg.interfaceName;
        matchSetting = "wireguard";
        matchType = "wireguard";
      }
    ];
  };
}
