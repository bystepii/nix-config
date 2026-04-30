{ lib, ... }:
{
  # Minimal home configuration for stepii
  # Add home-manager modules here as needed
  imports = lib.custom.scanPathsFilterPlatform ./.;
  # home.file = {
  #   # Avatar used by login managers like SDDM (must be PNG)
  #   ".face.icon".source = "${inputs.nix-assets}/images/avatars/emergentmind_avatar_200k.png";
  # };
}
