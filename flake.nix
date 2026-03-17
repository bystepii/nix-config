{
  description = "EmergentMind's Nix-Config Starter";
  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      # nix-darwin,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      baseLib = nixpkgs.lib;
      namespace = "stepii";
      secrets = inputs.nix-secrets;

      # ========== Extend lib with lib.custom ==========
      # NOTE: This approach allows lib.custom to propagate into hm
      # see: https://github.com/nix-community/home-manager/pull/3454
      lib = baseLib.extend (_self: _super: { custom = import ./lib { lib = baseLib; }; });

      readHosts =
        folder:
        baseLib.attrNames (
          baseLib.filterAttrs (_name: kind: kind == "directory") (builtins.readDir ./hosts/${folder})
        );

      mkHost = host: isDarwin: {
        ${host} =
          let
            systemFunc = if isDarwin then inputs.nix-darwin.lib.darwinSystem else baseLib.nixosSystem;
          in
          systemFunc {
            specialArgs = {
              inherit
                inputs
                outputs
                lib
                namespace
                secrets
                ;
              inherit isDarwin;
            };
            modules = [ ./hosts/${if isDarwin then "darwin" else "nixos"}/${host} ];
          };
      };

      mkMinimalHost = host: {
        "${host}Minimal" = baseLib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              inputs
              outputs
              lib
              namespace
              secrets
              ;
            isDarwin = false;
          };
          modules = [
            ./modules/common/host-spec.nix
            ./modules/hosts/nixos/disks.nix
            ./modules/hosts/nixos/impermanence
            inputs.home-manager.nixosModules.home-manager

            ./hosts/nixos/${host}/host-spec.nix
            ./hosts/nixos/${host}/disks.nix

            ./hosts/common/optional/minimal-configuration.nix
            ./hosts/nixos/${host}/hardware-configuration.nix
            { networking.hostName = host; }
          ];
        };
      };

      mkHostConfigs =
        hosts: isDarwin:
        let
          minimalHosts = baseLib.filter (
            h:
            h != "iso"
            && builtins.pathExists ./hosts/nixos/${h}/host-spec.nix
            && builtins.pathExists ./hosts/nixos/${h}/disks.nix
            && builtins.pathExists ./hosts/nixos/${h}/hardware-configuration.nix
          ) hosts;
        in
        baseLib.foldl' (acc: set: acc // set) { } (
          (map (host: mkHost host isDarwin) hosts) ++ (map mkMinimalHost minimalHosts)
        );

      hostNames = readHosts "nixos";

      nixosConfigurations = mkHostConfigs hostNames false;

    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];

      flake = {
        # Custom modifications/overrides to upstream packages
        overlays = import ./overlays {
          inherit inputs;
          lib = baseLib;
        };

        # Building configurations is available through `just rebuild` or `nixos-rebuild --flake .#hostname`
        inherit nixosConfigurations;

        # darwinConfigurations = builtins.listToAttrs (
        #   map (host: {
        #     name = host;
        #     value = nix-darwin.lib.darwinSystem {
        #       specialArgs = {
        #         inherit inputs outputs lib;
        #         isDarwin = true;
        #       };
        #       modules = [ ./hosts/darwin/${host} ];
        #     };
        #   }) (builtins.attrNames (builtins.readDir ./hosts/darwin))
        # );
      };

      perSystem =
        { system, ... }:
        let
          packagesPkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
          shellPkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.introdus.overlays.default
              self.overlays.default
            ];
          };
          checksPkgs = shellPkgs;
          formatter = checksPkgs.nixfmt-rfc-style;
          checks = import ./checks {
            inherit
              inputs
              system
              formatter
              ;
            pkgs = checksPkgs;
            lib = baseLib;
          };
        in
        {
          # Expose custom packages
          # NOTE: This is only for exposing packages externally.
          packages = nixpkgs.lib.packagesFromDirectoryRecursive {
            callPackage = nixpkgs.lib.callPackageWith packagesPkgs;
            directory = ./pkgs/common;
          };

          # Nix formatter available through 'nix fmt'
          inherit formatter checks;

          # Custom shell for bootstrapping on new hosts, modifying nix-config, and secrets management
          devShells = import ./shell.nix {
            pkgs = shellPkgs;
            inherit checks;
            lib = baseLib;
          };
        };
    };

  inputs = {
    #
    # ========= Official NixOS, Nix-Darwin, and HM Package Sources =========
    #
    # NOTE(starter): As with typical flake-based configs, you'll need to update the nixOS, hm,
    # and darwin version numbers below when new releases are available.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # The next two inputs are for pinning nixpkgs to stable vs unstable regardless of what the above is set to.
    # This is particularly useful when an upcoming stable release is in beta because you can effectively
    # keep 'nixpkgs-stable' set to stable for critical packages while setting 'nixpkgs' to the beta branch to
    # get a jump start on deprecation changes.
    # See also 'stable-packages' and 'unstable-packages' overlays at 'overlays/default.nix"
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    #
    # ========= Utilities =========
    #
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Secrets management. See ./docs/secretsmgmt.md
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Ephemeral root with persisted paths
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    # Pre-commit
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #
    # ========= Personal Repositories =========
    #
    introdus = {
      url = "git+https://codeberg.org/fidgetingbits/introdus?shallow=1&ref=ta";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Private secrets repo.  See ./docs/secretsmgmt.md
    # Authenticates via ssh and use shallow clone
    nix-secrets = {
      url = "git+ssh://git@github.com/bystepii/nix-secrets.git?ref=complex&shallow=1";
      inputs = { };
    };
  };
}
