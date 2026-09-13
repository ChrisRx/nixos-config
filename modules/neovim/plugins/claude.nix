{ ... }: {
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
    enable = true;
  };
  plugins.claudecode = {
    enable = true;
    settings = {
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
