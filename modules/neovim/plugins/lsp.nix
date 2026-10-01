{ pkgs, lib, ... }:
{
  autoCmd = [
    {
      event = [ "BufWritePre" ];
      pattern = [ "*.templ" ];
      callback.__raw = ''
        function()
          vim.lsp.buf.format({ async = false })
        end
      '';
    }
  ];
  extraPackages = with pkgs; [
    gopls
    golangci-lint-langserver
    gotests
    tailwindcss-language-server
    rust-analyzer
    lua-language-server
    templ
    htmx-lsp
    tree-sitter
    quickshell
  ];
  plugins = {
    lsp = {
      enable = lib.mkDefault true;
      inlayHints = true;
      keymaps.lspBuf = {
        "gd" = "definition";
        "gD" = "references";
        "gt" = "type_definition";
        "gi" = "implementation";
        "K" = "hover";
      };
      servers = {
        bashls.enable = lib.mkDefault true;
        buf_ls.enable = lib.mkDefault true;
        clangd.enable = lib.mkDefault true;
        qmlls.enable = lib.mkDefault true;
        lua_ls = {
          enable = lib.mkDefault true;
          settings.telemetry.enable = false;
        };
        gopls = {
          enable = lib.mkDefault true;
          package = null; # default pkgs.gopls
          settings = {
            "ui.diagnostics.vulncheck" = "Off";
          };
        };
        templ = {
          enable = lib.mkDefault true;
        };
        html = {
          enable = lib.mkDefault true;
        };
        tailwindcss = {
          enable = lib.mkDefault true;
        };
        nixd = {
          enable = lib.mkDefault true;
          # Without these nixd falls back to <nixpkgs>, which covers package
          # and stock NixOS option completion but nothing specific to this
          # flake: no home-manager options, no nixvim options, and none of the
          # options declared here (core.*, packages.*).
          #
          # Each provider is evaluated lazily in its own worker, so the first
          # completion in a fresh session comes back empty while that worker
          # evaluates. Retrying a second or two later populates it.
          rootMarkers = [
            "flake.nix"
            "default.nix"
            ".git"
          ];
          settings =
            let
              # nixd needs the flake and `toString ./.` expands to the absolute
              # path of the current working directory, which in most cases will
              # be the git repo root for the nix files being edited. Adding an
              # override environment variable $NIXD_FLAKE in case there is need
              # to specify an alternate for some reason.
              flake = ''
                (builtins.getFlake (let e = builtins.getEnv "NIXD_FLAKE"; in if e != "" then e else (toString ./.)))
              '';
              # Picks the right nixosConfigurations entry per machine.
              host = ''(builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile /etc/hostname))'';
            in
            {
              nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
              options = {
                nixos.expr = "${flake}.nixosConfigurations.\${${host}}.options";
                # home-manager here is a NixOS module, so its options live
                # under the users submodule rather than homeConfigurations.
                home_manager.expr = "(${flake}.nixosConfigurations.\${${host}}.options.home-manager.users.type.getSubOptions [ ])";
                nixvim.expr = "${flake}.packages.\${builtins.currentSystem}.neovim.options";
              };
            };
        };
      };
    };
    rustaceanvim = {
      enable = lib.mkDefault true;
      settings = {
        server = {
          default_settings = {
            rust-analyzer = {
              checkOnSave = true;
              check = {
                command = "check";
                extraArgs = [ "--no-deps" ];
                features = "all";
              };
              procMacro = {
                enable = true;
                attributes.enable = true;
                ignored = {
                  "async-trait" = [ "async_trait" ];
                  "napi-derive" = [ "napi" ];
                  "async-recursion" = [ "async_recursion" ];
                  "ctor" = [ "ctor" ];
                  "tokio" = [ "test" ];
                };
              };
              diagnostics.disabled = [
                "macro-error"
                "unlinked-file"
                "unresolved-macro-call"
                "unresolved-proc-macro"
                "proc-macro-disabled"
                "proc-macro-expansion-error"
              ];
            };
          };
        };
      };
    };
  };
}
