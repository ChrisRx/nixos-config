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
      glow = { enable = true; };
      which-key = { enable = true; };
      gitsigns = {
        enable = true;
        settings = {
          signs = {
            delete = { text = "󰍵"; };
            changedelete = { text = "󱕖"; };
          };
        };
      };
      gitlinker = { enable = true; };
      lastplace = { enable = true; };
      luasnip = {
        enable = true;
        # fromLua = [{ paths = ./snippets; }];
      };
      web-devicons = {
        enable = true;
        autoLoad = true;
        settings = {
          color_icons = true;
          variant = "dark";
          strict = true;
        };
      };
      comment = { enable = true; };
      tmux-navigator = {
        enable = true;
        autoLoad = true;
        settings = { disable_when_zoomed = 1; };
      };

      telescope = { enable = true; };
      colorizer = {
        enable = true;
        settings = {
          RRGGBB = true;
          tailwind = true;
        };
      };
      trouble = { enable = true; };
      # indent-blankline.enable = true;
      notify = {
        enable = true;
        # remove animations for performance
        settings = {
          stages = "static";
          timeout = 5000;
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

      mini = {
        enable = true;
        modules = {
          # tabline = { enable = true; };
          pairs = {
            enable = true;
            # modes = {
            #   insert = true;
            #   command = false;
            #   terminal = false;
            # };
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
    };
  };
}
