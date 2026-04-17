# FIXME(roles): This eventually should get slotted into some sort of 'role' thing
{
  osConfig,
  lib,
  secrets,
  ...
}:
let
  cfg = osConfig.hostSpec;
in
lib.mkIf cfg.isAdmin {
  sshAutoEntries = {
    enable = true;
    defaultUser = "ta";
    ykDomainHosts = [
      "genoa"
      "ghost"
      "gooey" # confirm
      "grief"
      "guppy"
      "gusto"
    ];
    ykNoDomainHosts = [
      "myth"
      cfg.networking.subnets.glade.wildcard
      cfg.networking.subnets.grove.wildcard
      cfg.networking.subnets.vm-lan.wildcard
    ]
    ++ lib.optional cfg.isWork secrets.work.git.servers;
  };
  programs.ssh.matchBlocks =
    let
      # ===== non-nixos hosts on internal subnets =====

      # TODO:
      # gladeSubnetHosts= [
      # ];
      groveSubnetHosts = [
        "glass"
        "gooey"
        "guard"
      ];
      extraSubnetEntries =
        hosts: subnet:
        hosts
        |> lib.lists.map (host: {
          "${host}" = lib.hm.dag.entryAfter [ "yubikey-hosts" ] {
            match = "host ${host},${host}.${cfg.domain}";
            hostname = "${host}.${cfg.domain}";
            user = cfg.networking.subnets.${subnet}.hosts.${host}.user;
            port = cfg.networking.subnets.${subnet}.hosts.${host}.sshPort;
          };
        })
        |> lib.attrsets.mergeAttrsList;
    in
    {
      # external hosts with
      "moth" = lib.hm.dag.entryAfter [ "yubikey-hosts" ] {
        host = "moth";
        hostname = "moth.${cfg.domain}";
        user = "${cfg.primaryUsername}";
        port = cfg.networking.ports.tcp.moth;
      };
      # "myth" = lib.hm.dag.entryAfter [ "yubikey-hosts" ] {
      #   host = "myth ${secrets.networking.domains.myth}";
      #   hostname = "${secrets.networking.domains.myth}";
      #   user = "admin";
      #   port = cfg.networking.ports.tcp.myth;
      # };
    }
    # // (extraSubnetEntries gladeSubnetHosts "glade")
    // (extraSubnetEntries groveSubnetHosts "grove");
}
