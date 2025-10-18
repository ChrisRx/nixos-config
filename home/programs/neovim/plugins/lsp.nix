{ pkgs, ... }: {
  programs.nixvim = {
    extraPackages = with pkgs; [
      gopls
      golangci-lint-langserver
      gotests
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
          nixd = { enable = true; };
        };
      };
      rustaceanvim = {
        enable = true;
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
  };
}
