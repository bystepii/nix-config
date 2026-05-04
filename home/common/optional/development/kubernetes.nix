# Kubernetes / Helm Dev Tools
{
  lib,
  pkgs,
  ...
}:
{
  home.packages = lib.attrValues {
    inherit (pkgs)
      kubectl
      kubernetes-helm
      ;
  };
}
