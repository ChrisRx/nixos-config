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
    # The compositor itself comes from nixpkgs-unstable, not a flake input. A
    # hyprland plugin loads only into the exact compositor build it was
    # compiled against (PLUGIN_INIT compares the two commit hashes and bails on
    # a mismatch), so the plugins below are source only and built in-tree
    # against `unstable.hyprland`. See `programs.hyprland.package` in
    # ./modules/desktop/hyprland/nixos.nix and `hyprlandPkg` in its home.nix.
    #
    # Upstream gloview does ship a flake, but its package builds against its
    # own patched compositor. Only the source is used, by
    # ./modules/desktop/hyprland/gloview.nix.
    gloview = {
      url = "github:fedsfarm/gloview";
      flake = false;
    };
    # Source only: upstream ships no flake. Built by
    # ./modules/desktop/hyprland/hypr-kinetic-scroll.nix against the same
    # compositor.
    hypr-kinetic-scroll = {
      url = "github:savonovv/hypr-kinetic-scroll";
      flake = false;
    };
    # Source only, same as above: no flake upstream. Built by
    # ./modules/desktop/hyprland/hypr3d.nix against the compositor's dev
    # output, which is exactly the headersRoot layout its CMakeLists wants.
    # Jolt is vendored in-tree rather than submoduled, so the plain fetch is
    # the whole source.
    #
    # Pinned to a rev, not a branch, because the five patches in
    # ./modules/desktop/hyprland/hypr3d.nix are written against this exact
    # tree and `git apply` is not fuzzy about it — upstream is pre-release and
    # rewrites the files they touch, so letting `nix flake update` carry this
    # input forward is what breaks the build. Moving it is therefore a manual
    # step: bump the rev here, rebuild, and rebase whichever patches upstream
    # has since absorbed or invalidated.
    Hypr3D = {
      url = "github:samine825/Hypr3D/7285e25cd68ee45139a4d78a83c07a44b5aba2c8";
      flake = false;
    };
  };
  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
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

      # `unstable` for the home modules that need it outside homeModules.default,
      # which overrides it with a plain definition. Keyed so that importing
      # several of those modules defines it once: the arg takes a single value,
      # and two mkDefault definitions of it conflict.
      unstableArg =
        { pkgs, lib, ... }:
        {
          key = "homeModules.unstableArg";
          _module.args.unstable = lib.mkDefault (mkUnstable pkgs.stdenv.hostPlatform.system);
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
            imports = [
              inputs.nixvim.homeModules.nixvim
              unstableArg
            ];

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
          };

        # The desktop modules on their own, for standalone home-manager on a
        # non-NixOS distro. Only the home halves come along: the compositor's
        # session entry, PAM and GPU drivers are left to the host. Enable with
        # `desktop.hyprland.enable = true`.
        hyprland = {
          # Without a key, importing this alongside homeModules.default (which
          # pulls it in too) would declare noctalia's options twice.
          key = "homeModules.hyprland";

          imports = [
            ./modules/desktop/home.nix
            # Here rather than in ./modules/desktop/hyprland/home.nix: that
            # file only sees inputs through `_module.args`, which `imports`
            # cannot read.
            inputs.noctalia.homeModules.default
            unstableArg
          ];

          # Read by ./modules/desktop/hyprland/home.nix, which explains the
          # name.
          _module.args.flakeInputs = inputs;
        };

        default =
          { pkgs, ... }:
          {
            imports = [
              ./modules/home
              self.homeModules.neovim
              self.homeModules.hyprland
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
