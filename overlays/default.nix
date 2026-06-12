#
# This file defines overlays/custom modifications to upstream packages
#

{ inputs, lib, ... }:

let
  overlays = {
    # Adds my custom packages
    # FIXME: Add per-system packages
    additions =
      final: prev:
      let
        # system = final.stdenv.hostPlatform.system;
      in
      (
        prev.lib.packagesFromDirectoryRecursive {
          callPackage = prev.lib.callPackageWith final;
          directory = ../pkgs;
        }
        # Any nixpkgs PRs that aren't upstream yet
        // {
          lens =
            let
              version = "2026.3.251250";
              pname = "lens-desktop";
              src = prev.fetchurl {
                url = "https://api.k8slens.dev/binaries/Lens-${version}-latest.x86_64.AppImage";
                hash = "sha512-q0vb6sl4XqoNhV83z16TWoqGNLA6J6wAyVmz28cBzzA5O9xSpMDIMiQPwQlgAnbCnCDaWc//HhXMmobaKWAUxA==";
              };
              appimageContents = prev.appimageTools.extractType2 {
                inherit pname version src;
              };
            in
            prev.appimageTools.wrapType2 {
              inherit pname version src;
              meta = prev.lens.meta // {
                inherit version;
              };
              nativeBuildInputs = [ prev.makeWrapper ];
              extraInstallCommands = ''
                wrapProgram $out/bin/${pname} \
                  --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
                install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
                install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/${pname}.png \
                   $out/share/icons/hicolor/512x512/apps/${pname}.png
                substituteInPlace $out/share/applications/${pname}.desktop \
                  --replace 'Exec=AppRun' 'Exec=${pname}'
              '';
              extraPkgs = pkgs: [ pkgs.nss_latest ];
            };
        }
      )
      # Other external inputs
      // {
      };

    linuxModifications =
      final: prev:
      lib.optionalAttrs prev.stdenv.isLinux ({
        # linuxPackages_6_18 = prev.linuxPackages_6_18.extend (
        #   _lfinal: lprev: {
        #     xpadneo = lprev.xpadneo.overrideAttrs (old: {
        #       patches = (old.patches or [ ]) ++ [
        #         (prev.fetchpatch {
        #           url = "https://github.com/orderedstereographic/xpadneo/commit/233e1768fff838b70b9e942c4a5eee60e57c54d4.patch";
        #           hash = "sha256-HL+SdL9kv3gBOdtsSyh49fwYgMCTyNkrFrT+Ig0ns7E=";
        #           stripLen = 2;
        #         })
        #       ];
        #     });
        #   }
        # );
        neovim = final.unstable.neovim;
        neovim-unwrapped = final.unstable.neovim-unwrapped;
        neovide = final.unstable.neovide;
        vimPlugins = final.unstable.vimPlugins;
      });

    modifications = final: prev: {
      # example = prev.example.overrideAttrs (previousAttrs: let ... in {
      # ...
      # });
      # System-wide default to CUDA 13 to match the NVIDIA driver
      cudaPackages = final.cudaPackages_13;

      # Firefox doesn't need CUDA in onnxruntime; building it with CUDA
      # is slow, uncached, and often broken.
      onnxruntime = prev.onnxruntime.override { cudaSupport = false; };
    };

    unstable-packages = final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (final.stdenv.hostPlatform) system;
        config.allowUnfree = true;
        overlays = [
          (unstable_final: unstable_prev: {
            bootdev-cli = unstable_prev.bootdev-cli.overrideAttrs (
              previousAttrs:
              let
                version = "1.29.2";
                hashes = {
                  "1.29.2" = "sha256-POOxwveDSQ3hiybFKmI2eQQEbxN45ubmfEUkLk7i/ng=";
                };
              in
              rec {
                inherit version;
                src = prev.fetchFromGitHub {
                  owner = "bootdotdev";
                  repo = "bootdev";
                  tag = "v${version}";
                  hash = hashes.${version} or "";
                };
                vendorHash = "sha256-ZDioEU5uPCkd+kC83cLlpgzyOsnpj2S7N+lQgsQb8uY=";
              }
            );
          })
        ];
      };
    };
  };
in
{
  default =
    final: prev:
    lib.attrNames overlays
    |> map (name: (overlays.${name} final prev))
    # nixfmt hack
    |> lib.mergeAttrsList;
}
