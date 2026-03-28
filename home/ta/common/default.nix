{ inputs, ... }:
{
  home.file = {
    # Avatar used by login managers like SDDM (must be PNG)
    ".face.icon".source = "${inputs.nix-assets}/images/avatars/emergentmind_avatar_200k.png";
  };
}
