{ inputs, lib, ... }:
{
  imports = (
    map lib.custom.relativeToRoot (
      map (f: "home/common/optional/${f}") [
        "browsers/brave.nix"
        # comes from module now
        # "browsers/firefox.nix"
        "networking/protonvpn.nix"

        "media.nix"
        "yazi.nix"

        "introdus-xdg.nix" # file associations
      ]
    )
  );

  home.packages = lib.attrValues {

  };

  home.file = {
    # Avatar used by login managers like SDDM (must be PNG)
    ".face.icon".source = "${inputs.nix-assets}/images/avatars/camera.png";
  };
}
