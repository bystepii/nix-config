{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = lib.flatten [
    inputs.introdus.homeManagerModules.default
    inputs.stylix.homeManagerModules.stylix
    (map lib.custom.relativeToRoot [
      "modules/home"
    ])
    (lib.custom.scanPaths ./.)
  ];

  home.packages = lib.attrValues {
    inherit (pkgs)

      # Packages that don't have custom configs go here
      coreutils # basic gnu utils
      curl
      eza # ls replacement
      dust # disk usage
      fd # tree style ls
      findutils # find
      jq # json pretty printer and manipulator
      nix-tree # nix package tree viewer
      neofetch # fancier system info than pfetch
      ncdu # TUI disk usage
      pciutils
      pfetch # system info
      pre-commit # git hooks
      p7zip # compression & encryption
      ripgrep # better grep
      usbutils
      tree # cli dir tree viewer
      unzip # zip extraction
      unrar # rar extraction
      wev # show wayland events. also handy for detecting keypress codes
      wget # downloader
      xdg-utils # provide cli tools such as `xdg-mime` and `xdg-open`
      xdg-user-dirs
      yq-go # yaml pretty printer and manipulator
      zip # zip compression
      ;
    inherit (pkgs.introdus)
      jq5 # json5-capable jq
      ;
  };

  # Sets whether to make programs use XDG directories whenever supported
  # NOTE: considered moving to introdus.xdg module but not worth effort
  home.preferXdgDirectories = true;

  programs.home-manager.enable = true;
}
