{ ... }: {
  imports = [
    ./barbar.nix
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

  programs.nixvim = {
    plugins = {
      colorizer = {
        enable = true;
        settings = {
          RRGGBB = true;
          tailwind = true;
        };
      };
      comment = { enable = true; };
      gitlinker = {
        # default mapping: <leader>gy
        enable = true;
      };
      gitsigns = {
        enable = true;
        settings = {
          signs = {
            delete = { text = "󰍵"; };
            changedelete = { text = "󱕖"; };
          };
        };
      };
      glow = { enable = true; };
      indent-blankline = {
        enable = true;
        settings = {
          indent = { char = "│"; };
          scope.enabled = false;
        };
      };
      lastplace = { enable = true; };
      luasnip = {
        enable = true;
        # fromLua = [{ paths = ./snippets; }];
      };
      mini = {
        enable = true;
        modules = {
          pairs = { enable = true; };
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
        enable = true;
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
        enable = true;
        # remove animations for performance
        settings = {
          stages = "static";
          timeout = 5000;
        };
      };
      tmux-navigator = {
        enable = true;
        autoLoad = true;
        settings = { disable_when_zoomed = 1; };
      };
      trouble = { enable = true; };
      which-key = { enable = true; };
      web-devicons = {
        enable = true;
        autoLoad = true;
        settings = {
          color_icons = true;
          variant = "dark";
          strict = true;
        };
      };
    };
  };
}
