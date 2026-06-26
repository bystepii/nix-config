{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.lxqt.lxqt-policykit ];

  systemd.user.services.lxqt-policykit-agent = {
    description = "LXQt PolicyKit Agent";
    serviceConfig = {
      ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
      Restart = "on-failure";
    };
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
  };
}
