{ lib, ... }:
{
  imports = (
    map lib.custom.relativeToRoot (
      [
        # ========== Required modules ==========
        "home/common/core"
        "home/ta/common"
      ]
      ++
        # ========== Optional modules ==========
        (map (f: "home/common/optional/${f}") [
          "helper-scripts"

          "atuin.nix"
          "sops.nix"
        ])
    )
  );

  introdus.services.yubikey-touch-detector.enable = true;
}
