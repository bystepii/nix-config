{
  ...
}:
{
  # home.packages = [ pkgs.keepassxc ];
  programs.keepassxc = {
    enable = true;
    settings = {
      Security.LockDatabaseIdle = false;
    };
  };

  # Enable the KeePassXC native messaging host for Firefox
  # programs.firefox = lib.mkIf config.programs.firefox.enable {
  #   nativeMessagingHosts = [ pkgs.keepassxc ];
  # };
}
