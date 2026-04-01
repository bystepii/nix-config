{ pkgs, ... }:
{
  imports = [
    # Packages with custom configs go here
    ./gnome
    ./niri

    ########## Shell ##########
    ./noctalia.nix

    ########## Utilities ##########
    ./services/dunst.nix # Notification daemon
    ./services/kanshi.nix # Monitor profiles

    ./hyprlock.nix
    ./rofi.nix # app launcher
    ./waybar.nix # infobar

    #./wlogout # wayland logout menu (import as needed by specific WM)
    #./playerctl.nix # cli util and lib for controlling media players that implement MPRIS
  ];
  home.packages = [
    pkgs.pulseaudio # add pulse audio to the user path
    pkgs.pavucontrol # gui for pulseaudio server and volume controls
    pkgs.wl-clipboard # wayland copy and paste
    pkgs.galculator # gtk based calculator
  ];
}
