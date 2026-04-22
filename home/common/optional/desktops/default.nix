{ pkgs, ... }:
{
  imports = [
    # Packages with custom configs go here
    # ./gnome # don't enable through default anymore
    ./niri

    ########## Shell ##########
    ./noctalia.nix

    ########## Utilities ##########
    ./services/kanshi.nix # Monitor profiles

    #./playerctl.nix # cli util and lib for controlling media players that implement MPRIS
  ];
  home.packages = [
    pkgs.pulseaudio # add pulse audio to the user path
    pkgs.pavucontrol # gui for pulseaudio server and volume controls
    pkgs.wl-clipboard # wayland copy and paste
    pkgs.galculator # gtk based calculator
  ];
}
