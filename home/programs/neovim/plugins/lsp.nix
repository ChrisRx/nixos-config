{ pkgs, ... }: {
  programs.nixvim = {
    extraPackages = with pkgs; [
      gopls
      golangci-lint-langserver
      tailwindcss-language-server
      rust-analyzer
      lua-language-server
      templ
      htmx-lsp
    ];
    plugins = {
      lsp = {
        enable = true;
        inlayHints = true;
        keymaps.lspBuf = {
          "gd" = "definition";
          "gD" = "references";
          "gt" = "type_definition";
          "gi" = "implementation";
          "K" = "hover";
        };
        servers = {
          bashls.enable = true;
          clangd.enable = true;
          lua_ls = {
            enable = true;
            settings.telemetry.enable = false;
          };
          gopls = {
            enable = true;
            package = null; # default pkgs.gopls
          };
          templ = { enable = true; };
          html = { enable = true; };
          tailwindcss = { enable = true; };

          nixd = {
            enable = true;
            # extraOptions.offset_encoding = "utf-8";
            # settings = {
            #   nixpkgs.expr = ''import (builtins.getFlake "${self}").inputs.nixpkgs { }'';
            #   options = {
            #     nixvim.expr = ''(builtins.getFlake "${self}").packages.${system}.default.options'';
            #   };
            # settings = let
            #   flakeExpr =
            #     # nix
            #     ''(builtins.getFlake "''${self}")"'';
            #   systemExpr =
            #     # nix
            #     "\${builtins.currentSystem}";
            # in {
            #   # formatting.command = [ "nix fmt" ];
            #
            #   nixpkgs.expr =
            #     # nix
            #     "import ${flakeExpr}.inputs.nixpkgs { system = ${systemExpr}; }";
            #
            #   options = {
            #     # NOTE: These slow down everything significantly
            #
            #     nixvim.expr =
            #       # nix
            #       "${flakeExpr}.packages.${systemExpr}.nvim.options";
            #
            #     nixos.expr =
            #       # nix
            #       "${flakeExpr}.inputs.nixosConfigurations.fw13.options";
            #
            # home-manager.expr =
            #   # nix
            #   "${flakeExpr}.inputs.homeConfigurations.fw13.options";
            #   };
            # };
            # settings.expr = "import <nixpkgs> { }";
            # extraOptions = {
            #   fw13 = {
            #     expr =
            #       "(builtins.getFlake(toString ./.)).nixosConfigurations.fw13.options";
            #   };
            #   home-manager = {
            #     expr =
            #       "(builtins.getFlake(toString ./.)).nixosConfigurations.fw13.options.home-manager.users.type.getSubOptions []";
            #   };
            # };

            # settings = {
            #   nixpkgs = {
            #     expr =
            #       "import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }";
            #   };
            #   options = {
            #     nixos = {
            #       expr =
            #         "(builtins.getFlake(toString ./.)).nixosConfigurations.fw13.options";
            #     };
            #     nixvim = {
            #       expr =
            #         "(builtins.getFlake(toString ./.)).nixosConfigurations.fw13.options";
            #     };
            #     home-manager = {
            #       expr =
            #         "(builtins.getFlake(toString ./.)).nixosConfigurations.fw13.options.home-manager.users.type.getSubOptions []";
            #     };
            #   };
            # };

          };
        };
      };
    };
  };
}

# require("lspconfig").nixd.setup({
#     cmd = { "nixd" },
#     settings = {
#         nixd = {
#             nixpkgs = {
#                 -- For flake.
#                 -- This expression will be interpreted as "nixpkgs" toplevel
#                 -- Nixd provides package, lib completion/information from it.
#                 -- Resource Usage: Entries are lazily evaluated, entire nixpkgs takes 200~300MB for just "names".
#                 -- Package documentation, versions, are evaluated by-need.
#                 expr = "import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }",
#             },
#             formatting = {
#                 command = { "nixfmt" }, -- or nixfmt or nixpkgs-fmt
#             },
#             options = {
#                 nixos = {
#                     expr = "let flake = builtins.getFlake(toString ./.); in flake.nixosConfigurations.nixos.options",
#                 },
#                 home_manager = {
#                     expr = 'let flake = builtins.getFlake(toString ./.); in flake.nixosConfigurations.nixos.options.home-manager.users.type.getSubOptions []',
#                 },
#             },
#         },
#     },
# })
