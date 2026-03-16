# NOTE(starter): This is just a basic enabling of the XFCE windows manager for simplicity
{
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.displayManager.defaultSession = "xfce";
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.desktopManager.xfce.enableScreensaver = false;
}
