{ lib, ... }:
{
  imports = (
    map lib.custom.relativeToRoot (
      [
        # ========== Required modules ==========
        "home/common/core"
        "home/stepii/common"
      ]
      ++
        # ========== Optional modules ==========
        (map (f: "home/common/optional/${f}") [
          "desktops/niri"
          "desktops/services/kanshi.nix"
          "desktops/noctalia.nix"
          "networking/protonvpn.nix"
          "extrabrowsers"
          "comms/"
          "kitty.nix"
          "yazi.nix"
          "development"
          "sops.nix"
          "keepassxc"
          "docker.nix"
        ])
    )
  );

  # home = {
  #   stateVersion = "23.05";
  #   homeDirectory = "/home/stepii";
  #   username = "stepii";
  # };
}
