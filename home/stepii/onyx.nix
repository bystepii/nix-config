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
          "comms/"
          "kitty.nix"
          "yazi.nix"
          "development"
          "sops.nix"
          "keepassxc"
        ])
    )
  );

  # home = {
  #   stateVersion = "23.05";
  #   homeDirectory = "/home/stepii";
  #   username = "stepii";
  # };
}
