{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = [ pkgs.keepassxc ];

  # Enable the KeePassXC native messaging host for Firefox
  programs.firefox = lib.mkIf config.programs.firefox.enable {
    nativeMessagingHosts = [ pkgs.keepassxc ];
  };
}
