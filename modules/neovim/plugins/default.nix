{ lib, ... }: {
  imports = [
    ./barbar.nix
    ./claude.nix
    ./cmp.nix
    ./gitblame.nix
    ./go-nvim.nix
    ./goto-preview.nix
    ./lsp.nix
    ./lualine.nix
    ./none-ls.nix
    ./nvim-tree.nix
    ./telescope.nix
    ./treesitter.nix
  ];

  plugins = {
    colorizer = {
      enable = lib.mkDefault true;
      settings = {
        RRGGBB = true;
        tailwind = true;
      };
    };
    comment = {
      enable = lib.mkDefault true;
    };
    gitlinker = {
      # default mapping: <leader>gy
      enable = lib.mkDefault true;
    };
    gitsigns = {
      enable = lib.mkDefault true;
      settings = {
        signs = {
          delete = {
            text = "󰍵";
          };
          changedelete = {
            text = "󱕖";
          };
        };
      };
    };
    glow = {
      enable = lib.mkDefault true;
    };
    indent-blankline = {
      enable = lib.mkDefault true;
      settings = {
        indent = {
          char = "│";
        };
        scope.enabled = false;
      };
    };
    lastplace = {
      enable = lib.mkDefault true;
    };
    luasnip = {
      enable = lib.mkDefault true;
      # fromLua = [ { paths = ../snippets; } ];
    };
    mini = {
      enable = lib.mkDefault true;
      modules = {
        pairs = {
          enable = lib.mkDefault true;
        };
        surround = {
          mappings = {
            add = "gsa";
            delete = "gsd";
            find = "gsf";
            find_left = "gsF";
            highlight = "gsh";
            replace = "gsr";
            update_n_lines = "gsn";
          };
        };
      };
    };
    noice = {
      enable = lib.mkDefault true;
      settings = {
        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
          notify.enabled = true;
          progress.enabled = true;
          signature.enabled = true;
        };

        presets = {
          bottom_search = false;
          command_palette = true;
          long_message_to_split = true;
          inc_rename = true;
          lsp_doc_border = true;
        };
      };
    };
    notify = {
      enable = lib.mkDefault true;
      # remove animations for performance
      settings = {
        stages = "static";
        timeout = 5000;
      };
    };
    tmux-navigator = {
      enable = lib.mkDefault true;
      autoLoad = true;
      settings = {
        disable_when_zoomed = 1;
        no_mappings = 1;
      };
    };
    trouble = {
      enable = lib.mkDefault true;
    };
    which-key = {
      enable = lib.mkDefault true;
    };
    web-devicons = {
      enable = lib.mkDefault true;
      autoLoad = true;
      settings = {
        color_icons = true;
        variant = "dark";
        strict = true;
      };
    };
  };
}
