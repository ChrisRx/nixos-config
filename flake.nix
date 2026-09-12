{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      self,
      ...
    }@inputs:
    let
      username = "chris";
      system = "x86_64-linux";

      # Build the neovim package against a caller-supplied nixpkgs, so consumers
      # get an nvim built from their own tree. Only nixvim's option definitions
      # come from nixvim's own pin.
      mkNeovim =
        pkgs:
        inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
          inherit pkgs;
          module = import ./modules/neovim;
        };
    in
    {
      nixosModules = {
        core = import ./modules/nixos/core;
        nvidia = import ./modules/nixos/nvidia;
      };

      packages.${system}.neovim = mkNeovim (
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );

      homeModules = {
        neovim =
          { pkgs, ... }:
          {
            home.packages = [ (mkNeovim pkgs) ];
            home.sessionVariables.EDITOR = "nvim";
          };

        default =
          { pkgs, ... }:
          {
            imports = [
              ./modules/home
              self.homeModules.neovim
            ];

            # Passed as a module arg rather than a pkgs overlay so it applies
            # identically under standalone home-manager and under NixOS with
            # useGlobalPkgs, where a home-level overlay would be ignored.
            _module.args.unstable = import nixpkgs-unstable {
              inherit (pkgs.stdenv.hostPlatform) system;
              config.allowUnfree = true;
            };
          };
      };
      nixosConfigurations = {
        htpc = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/htpc ];
          specialArgs = {
            host = "htpc";
            inherit self inputs username;
          };
        };
      };
      nixosConfigurations = {
        fw13 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/fw13
            nixos-hardware.nixosModules.framework-amd-ai-300-series
          ];
          specialArgs = {
            host = "fw13";
            inherit self inputs username;
          };
        };
      };
    };
}
