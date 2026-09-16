{ unstable, lib, ... }: {
  keymaps = [
    {
      mode = [
        "n"
      ];
      key = "<leader>cc";
      action = "<cmd>ClaudeCode<cr>";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      mode = [
        "v"
      ];
      key = "<leader>cc";
      action = "<cmd>ClaudeCodeFocus<cr>";
      options = {
        noremap = true;
        silent = true;
      };
    }
  ];
  plugins.snacks = {
    enable = lib.mkDefault true;
  };
  plugins.claudecode = {
    enable = lib.mkDefault true;
    # nixos-26.05 froze claudecode.nvim at 2026-04-27, two months before
    # `diff_opts.layout = "unified"` landed upstream. Passing "unified" to the
    # frozen plugin trips an assert in its setup(), which aborts the rest of
    # init.lua, so this one plugin tracks unstable.
    package = unstable.vimPlugins.claudecode-nvim;
    settings = {
      diff_opts = {
        # single buffer with deleted lines inline, VS Code style
        layout = "unified";
        keep_terminal_focus = true;
      };
      terminal = {
        provider = "snacks";
        # fraction of the editor width, must be > 0 and < 1
        split_width_percentage = 0.45;
        snacks_win_opts = {
          # snacks defaults to Normal:SnacksNormal, which resolves to
          # NormalFloat (catppuccin paints that mantle). Point it back at
          # Normal so the transparent background shows through.
          wo = {
            winhighlight = "Normal:Normal,NormalNC:Normal,WinBar:Normal,WinBarNC:Normal";
          };
        };
      };
    };
  };
}
