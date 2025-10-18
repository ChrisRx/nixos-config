{ pkgs, ... }: {
  imports = [ ./keymaps.nix ./plugins ];

  home.sessionVariables = { EDITOR = "nvim"; };

  programs.nixvim = {
    enable = true;
    vimAlias = true;
    extraPackages = with pkgs; [ gcc cmake gnumake fzf ];

    opts = {
      number = true;
      expandtab = true;
      shiftwidth = 2;
      smartindent = true;
      tabstop = 2;
      softtabstop = 2;
      numberwidth = 2;
      ruler = false;
      clipboard = "unnamedplus";
      timeoutlen = 400;
      undofile = true;
    };

    extraConfigLuaPre = ''
      vim.deprecate = function() end
      vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
      vim.fn.sign_define("DiagnosticSignHint", { text = "󰌵", texthl = "DiagnosticHint", linehl = "", numhl = "" })
      vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
    '';

    diagnostic.settings = { virtual_text = true; };
    highlightOverride = {
      DevIconMakefile.fg = "#a6f3a1";
      DevIconDefault.fg = "#a6f3a1";
    };

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        color_overrides = {
          mocha = {
            blue = "#65bcff";
            text = "#edede4";
            green = "#a6f3a1";
          };
        };

        custom_highlights.__raw = ''
          function(colors)
            return {
              ["Include"] = { fg = colors.blue },
              ["@module"] = { fg = colors.red },
              ["@variable.member"] = { fg = colors.red },
            }
          end
        '';
        transparent_background = true;
        no_italic = true;
        default_integrations = true;
        integrations = {
          cmp = true;
          gitsigns = true;
          notify = true;
          mini = {
            enabled = true;
            indentscope_color = "";
          };
          nvimtree = true;
          treesitter = true;
          native_lsp = {
            enabled = true;
            inlay_hints = { background = true; };
            virtual_text = {
              errors = [ "italic" ];
              hints = [ "italic" ];
              information = [ "italic" ];
              warnings = [ "italic" ];
              ok = [ "italic" ];
            };
            underlines = {
              errors = [ "underline" ];
              hints = [ "underline" ];
              information = [ "underline" ];
              warnings = [ "underline" ];
            };
          };
        };
      };
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
