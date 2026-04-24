{
  lib,
  pkgs,
  osConfig,
  ...
}:
{
  imports = [
    ./scripts.nix
  ];
  home = {
    packages = lib.attrValues {
      inherit (pkgs.unstable)
        niri
        xwayland-satellite # xwayland support
        ;
    };
    file =
      let
        hostPath = "hosts/nixos/${osConfig.hostSpec.hostName}/niri";
        finalConfig =
          lib.flatten [
            # order matters
            ./inputs.kdl
            (map lib.custom.relativeToRoot [
              "${hostPath}/outputs.kdl"
              "${hostPath}/workspaces.kdl"
              "${hostPath}/startup.kdl"
            ])
            ./binds.kdl
            ./rules.kdl
            ./config.kdl
          ]
          |> lib.concatMapStringsSep "\n" lib.readFile;
      in
      {
        ".config/niri/config.kdl".text = finalConfig;
        ".config/niri/animations/" = {
          source = ./animations;
          recursive = true;
        };
      };
  };
}
