{ lib, pkgs, ... }:
{
  environment.systemPackages = lib.attrValues {
    inherit (pkgs.nvtopPackages)
      amd
      intel
      nvidia
      ;
  };
}
