{ pkgs, lib, ... }: {
  imports = [
    ./keymaps.nix
    ./plugins
  ];

  vimAlias = true;
  extraPackages = with pkgs; [
    gcc
    cmake
    gnumake
    fzf
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

    # [ver:3,hor:6] lines moved per mouse-wheel tick. The compositor's
    # input.touchpad.scroll_factor cannot fix scrolling in here: ghostty
    # converts touchpad scroll into discrete wheel ticks, and neovim then
    # multiplied each tick by 3 lines, so it stayed ~3x faster than every
    # other window. This is the only knob on that multiplier.
    #
    # To try other values without a rebuild: :set mousescroll=ver:2,hor:4
    mousescroll = "ver:1,hor:2";
  };

  extraConfigLuaPre = ''
    vim.deprecate = function() end
    vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticError", linehl = "", numhl = "" })
    vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
    vim.fn.sign_define("DiagnosticSignHint", { text = "󰌵", texthl = "DiagnosticHint", linehl = "", numhl = "" })
    vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticInfo", linehl = "", numhl = "" })

    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
      pattern = "term://*",
      callback = function()
        vim.cmd("startinsert")
      end,
    })
  '';

  diagnostic.settings = {
    virtual_text = true;
  };
  highlightOverride = {
    DevIconMakefile.fg = "#a6f3a1";
    DevIconDefault.fg = "#a6f3a1";
  };

  colorschemes.catppuccin = {
    enable = lib.mkDefault true;
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
          inlay_hints = {
            background = true;
          };
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
}
