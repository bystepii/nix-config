# Terraform / IaC Dev Tools
{
  lib,
  pkgs,
  ...
}:
{
  home.packages = lib.attrValues {
    inherit (pkgs)
      terraform
      tflint
      terraform-docs
      ;
  };

  # Bash completion using the nix store path (NixOS has no /usr/bin/terraform)
  programs.bash.initExtra = ''
    complete -C ${pkgs.terraform}/bin/terraform terraform
  '';
}
