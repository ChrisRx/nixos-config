{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    iris.url = "github:versenilvis/iris/main";
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

      # Systems the neovim package is exposed for. The NixOS hosts below stay on
      # `system`; this list only widens `packages` so the vendored config can be
      # built for macOS too.
      packageSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs packageSystems;

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

      packages = forAllSystems (system: {
        neovim = mkNeovim (
          import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          }
        );
      });

      # CI runs the Taskfile via `nix develop -c task`, so the task runner comes
      # from this flake's pinned nixpkgs. The bare `nixpkgs` registry alias
      # resolves to unstable, which has dropped x86_64-darwin and throws on
      # evaluation there.
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShellNoCC { packages = [ pkgs.go-task ]; };
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
