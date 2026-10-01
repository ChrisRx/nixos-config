{ unstable, lib, ... }:
let
  # The claude terminal opens as a vertical split 45% of the editor wide (see
  # split_width_percentage below). With nvim-tree also up that leaves the file
  # buffer squeezed into a third column, so the tree goes away on the way in.
  #
  # Only when claude is about to *appear*: both commands are toggles, and
  # dropping the tree as a side effect of hiding claude would be surprising.
  # "Appear" is read off the terminal buffer's window count rather than the
  # buffer's existence, because the snacks provider keeps a hidden terminal's
  # buffer valid, so get_active_terminal_bufnr() alone cannot tell the two
  # states apart.
  #
  # Closing the tree *before* the command, not after, keeps the split arithmetic
  # honest: claude then sizes itself against the full-width editor instead of
  # against a layout that is about to lose a 30-column window.
  #
  # Both requires are pcall'd. ../default.nix enables these plugins with
  # mkDefault, so a host can turn either one off independently and this keymap
  # still has to work.
  closeTreeThen = cmd: ''
    function()
      local visible = false
      local ok, terminal = pcall(require, "claudecode.terminal")
      if ok then
        local bufnr = terminal.get_active_terminal_bufnr()
        local info = bufnr and vim.fn.getbufinfo(bufnr)[1]
        visible = info ~= nil and #info.windows > 0
      end

      if not visible then
        local tree_ok, tree = pcall(require, "nvim-tree.api")
        if tree_ok and tree.tree.is_visible() then
          tree.tree.close()
        end
      end

      vim.cmd("${cmd}")
    end
  '';
in
{
  keymaps = [
    {
      mode = [
        "n"
      ];
      key = "<leader>cc";
      action.__raw = closeTreeThen "ClaudeCode";
      options = {
        desc = "Toggle Claude Code";
        noremap = true;
        silent = true;
      };
    }
    {
      mode = [
        "v"
      ];
      key = "<leader>cc";
      action.__raw = closeTreeThen "ClaudeCodeFocus";
      options = {
        desc = "Focus Claude Code";
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
