{ inputs, lib, ... }:
{
  imports = (
    map lib.custom.relativeToRoot (
      [
        #
        # ========== Required Configs ==========
        #
        #FIXME: after fixing user/home values in HM
        "home/common/core"
        "home/common/core/nixos.nix"

        "home/ta/common/nixos.nix"
      ]
      ++
        #
        # ========== Host-specific Optional Configs ==========
        #
        (map (f: "home/common/optional/${f}") [
          "browsers"
          "comms"
          "desktops" # default is niri
          "development"
          "gaming"
          "helper-scripts"
          "tools"
          "zellij"

          "atuin.nix"
          "ebooks.nix"
          "media.nix"
          "introdus-xdg.nix" # file associations
          "sops.nix"
          "yazi.nix"
        ])
    )
  );

  introdus.services.awww = {
    enable = false;
    wallpaperDir = "/home/ta/sync/wallpaper/hostCollections/ghost/";
  };

  services.yubikey-touch-detector = {
    enable = true;
    notificationSound = true;
  };
  system.ssh-motd = {
    enable = true;
    banner = "${inputs.nix-assets}/images/banners/ghost.png";
  };
}
