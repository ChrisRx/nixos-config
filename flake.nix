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
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    catppuccin.url = "github:catppuccin/nix";
    # A hyprland plugin loads only into the exact compositor build it was
    # compiled against — PLUGIN_INIT compares the two commit hashes and bails
    # on a mismatch — so both sides have to name this same input. See
    # `programs.hyprland.package` in ./modules/desktop/hyprland/nixos.nix and
    # `wayland.windowManager.hyprland.package` in its home.nix; changing this
    # url without those is what produces a plugin that silently never loads.
    hyprland.url = "github:hyprwm/Hyprland/v0.56.0";
    gloview = {
      url = "github:fedsfarm/gloview";
      inputs.hyprland.follows = "hyprland";
    };
  };
  # hyprland's cache is what keeps the `hyprland` input above from being a
  # local build of the compositor and its whole hypr* dependency tree (~15
  # derivations). Without it the first rebuild after the pin moves compiles all
  # of them.
  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
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

      lib = nixpkgs.lib.extend (
        final: prev: {
          extra = import ./lib {
            inherit inputs username;
            lib = final;
          };
        }
      );

      # nixvim runs its own `evalModules` and builds the `lib` module arg from
      # its own pin, so nothing under ./modules/neovim sees the extension above
      # unless it is handed in explicitly. `evalNixvim` asserts that any lib
      # passed through `extraSpecialArgs` still carries nixvim's own helpers,
      # hence layering nixvim's overlay on top rather than passing `lib` bare.
      nixvimLib = lib.extend inputs.nixvim.lib.overlay;

      # nixpkgs-unstable instantiated for one system. Shared by the home
      # modules and the neovim package so both sides resolve to a single
      # instance rather than evaluating the tree twice.
      mkUnstable =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

      # Build the neovim package against a caller-supplied nixpkgs, so consumers
      # get an nvim built from their own tree. Only nixvim's option definitions
      # come from nixvim's own pin.
      #
      # `unstable` has to ride in on extraSpecialArgs: nixvim runs its own
      # module-system evaluation, so home-manager's `_module.args.unstable`
      # is not in scope for anything under ./modules/neovim.
      mkNeovim =
        {
          pkgs,
          unstable,
        }:
        inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
          inherit pkgs;
          extraSpecialArgs = {
            inherit unstable;
            lib = nixvimLib;
          };
          module = import ./modules/neovim;
        };
    in
    {
      nixosModules = {
        core = import ./modules/nixos/core;
        nvidia = import ./modules/nixos/nvidia;

        # System-wide counterpart to homeModules.neovim, for hosts that want
        # nvim in /run/current-system rather than per-user. Same option tree,
        # so `programs.nixvim.*` is overridable here too. Importing both on one
        # host is redundant; pick whichever layer owns the editor.
        neovim =
          { pkgs, lib, ... }:
          {
            imports = [ inputs.nixvim.nixosModules.nixvim ];

            programs.nixvim = {
              enable = true;
              defaultEditor = true;
              imports = [ ./modules/neovim ];
              nixpkgs.useGlobalPackages = true;
              wrapRc = lib.mkDefault true;

              # NixOS evaluation has no `unstable` module arg to inherit, so
              # this side resolves it directly. See homeModules.neovim.
              _module.args.unstable = mkUnstable pkgs.stdenv.hostPlatform.system;
            };
          };
      };

      packages = forAllSystems (system: {
        neovim = mkNeovim {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          unstable = mkUnstable system;
        };
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
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.go-task
              pkgs.jq
              pkgs.curl
            ];
          };
        }
      );

      homeModules = {
        neovim =
          {
            pkgs,
            lib,
            unstable,
            ...
          }:
          {
            # Going through nixvim's own home-manager module rather than
            # dropping `mkNeovim`'s package into `home.packages` is what makes
            # the whole option tree visible to importers: `programs.nixvim.*`
            # becomes a real submodule option here, so a consumer can override
            # anything under it. A pre-built package has no options to merge.
            imports = [ inputs.nixvim.homeModules.nixvim ];

            programs.nixvim = {
              enable = true;
              defaultEditor = true;
              imports = [ ./modules/neovim ];

              # Off by default, in which case nixvim instantiates nixpkgs from
              # its own pin and the importer's `config` (notably allowUnfree,
              # which cmp-emoji needs) does not apply. Keeps this module's
              # behaviour matched to `mkNeovim`, which builds against the
              # caller's tree.
              nixpkgs.useGlobalPackages = true;

              # nixvim's home-manager wrapper defaults this to false, which
              # would write the config out to ~/.config/nvim instead of sealing
              # it into the wrapper. Held at the previous behaviour, matching
              # `packages.<system>.neovim`; mkDefault so importers can flip it.
              wrapRc = lib.mkDefault true;

              # nixvim evaluates this submodule separately, so `unstable` has to
              # be re-declared inside it; the outer home-manager module arg is
              # not in scope for anything under ./modules/neovim.
              _module.args.unstable = unstable;
            };

            # homeModules.default normally supplies this; the mkDefault keeps
            # this module importable on its own, where nothing else defines it.
            _module.args.unstable = lib.mkDefault (mkUnstable pkgs.stdenv.hostPlatform.system);
          };

        default =
          { pkgs, ... }:
          {
            imports = [
              ./modules/home
              self.homeModules.neovim
              inputs.catppuccin.homeModules.catppuccin
            ];

            # Passed as a module arg rather than a pkgs overlay so it applies
            # identically under standalone home-manager and under NixOS with
            # useGlobalPkgs, where a home-level overlay would be ignored.
            _module.args.unstable = mkUnstable pkgs.stdenv.hostPlatform.system;
          };
      };
      nixosConfigurations = {
        htpc = lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/htpc ];
          specialArgs = {
            host = "htpc";
            inherit self inputs username;
          };
        };
      };
      nixosConfigurations = {
        fw13 = lib.nixosSystem {
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
