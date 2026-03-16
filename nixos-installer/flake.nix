{
  description = "Minimal NixOS configuration for bootstrapping systems";

  inputs = {
    # FIXME(starter): adjust nixos version for the minimal environment as desired.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko"; # Declarative partitioning and formatting
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      minimalSpecialArgs = {
        inherit inputs outputs;
        lib = nixpkgs.lib.extend (self: super: { custom = import ../lib { inherit (nixpkgs) lib; }; });
      };

      newConfig =
        name: disk: swapSize: impermanence:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = minimalSpecialArgs;
          modules = [
            # Shared reusable disk module (imports disko internally)
            ../modules/hosts/nixos/disks.nix
            ../modules/hosts/nixos/impermanence
            {
              hostSpec.persistFolder = "/persist";
              system.disks = {
                enable = true;
                primary = disk;
                useLuks = false;
                swapSize = if swapSize > 0 then swapSize else null;
              };
              system.impermanence.enable = impermanence;
            }
            ./minimal-configuration.nix
            ../hosts/nixos/${name}/hardware-configuration.nix

            { networking.hostName = name; }
          ];
        };
    in
    {
      nixosConfigurations = {
        # This should mimic what is specified in the respective `nix-config/hosts/[platform]/[hostname]/default.nix`
        # Add entries for each host you will be bootstrapping

        # host = newConfig "name" "disk" swapSize impermanence
        # Swap size is in GiB
        nix-vm = newConfig "nix-vm" "/dev/vda" 4 true;
      };
    };
}
