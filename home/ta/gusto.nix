{ inputs, lib, ... }:
{
  imports = (
    map lib.custom.relativeToRoot (
      [
        # ========== Required common modules ==========
        # FIXME: after fixing user/home values in HM
        "home/common/core"
        "home/common/core/nixos.nix"

        "home/ta/common/nixos.nix"
      ]
      ++
        # ========== Optional modules==========
        (map (f: "home/common/optional/${f}") [
          "browsers/brave.nix" # for testing against 'media' user
          # firefox comes from module now
          "helper-scripts"

          "atuin.nix"
          "sops.nix"
          "introdus-xdg.nix" # file associations
        ])
    )
  );

  services.yubikey-touch-detector.enable = true;
  services.yubikey-touch-detector.notificationSound = true;

  system.ssh-motd = {
    enable = true;
    banner = "${inputs.nix-assets}/images/banners/gusto.png";
  };
}
