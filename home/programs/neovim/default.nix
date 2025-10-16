{ pkgs, ... }: {
  imports = [ ./keymaps.nix ./plugins ];

  home.sessionVariables = { EDITOR = "nvim"; };

  programs.nixvim = {
    enable = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      gcc
      cmake
      gnumake
      fzf

      # go
      gopls
      golangci-lint-langserver
      gotests
    ];

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

    diagnostic.settings = {
      virtual_lines = {
        # current_line = true;
        # only_current_line = true;
      };
      virtual_text = true;
    };
    # rosewater = "#f5e0dc",
    # flamingo = "#f2cdcd",
    # pink = "#f5c2e7",
    # mauve = "#cba6f7",
    # red = "#f38ba8",
    # maroon = "#eba0ac",
    # peach = "#fab387",
    # yellow = "#f9e2af",
    # green = "#a6e3a1",
    # teal = "#94e2d5",
    # sky = "#89dceb",
    # sapphire = "#74c7ec",
    # blue = "#89b4fa",
    # lavender = "#b4befe",
    # text = "#cdd6f4",
    # subtext1 = "#bac2de",
    # subtext0 = "#a6adc8",
    # overlay2 = "#9399b2",
    # overlay1 = "#7f849c",
    # overlay0 = "#6c7086",
    # surface2 = "#585b70",
    # surface1 = "#45475a",
    # surface0 = "#313244",
    # base = "#1e1e2e",
    # mantle = "#181825",
    # crust = "#11111b",

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
            # base = "#1e1e2f";
            # blue = "#89b4fa";
            # blue = "#70a0fa";
            # blue = "#82aaff";
            # blue = "#3e68d7";
            blue = "#65bcff";
            # blue = "#0db9d7";
            # blue = "#89ddff";
            # blue = "#b4f9f8";
            # blue = "#394b70";
            # text = "#cdd6f4";
            text = "#edede4";
            # teal = "#94e2d5";
            # teal = "#94f2d5";
            # green = "#a6e3a1";
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
