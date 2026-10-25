{ unstable, lib, ... }:
let
  # fraction of the editor width, must be > 0 and < 1
  splitWidthPercentage = 0.45;

  # Columns the claude split never drops below, whatever the fraction above
  # works out to. Claude's TUI wraps its prompt and tool output badly under
  # roughly a standard terminal width, and inside a tmux pane that is sharing
  # the screen 45% of the editor is often well short of that. The code buffer
  # gives up the difference: the claude split is more useful at this width than
  # the buffer is useful with the extra columns.
  minWidth = 80;

  # Lua helpers shared by the keymaps and the autocmds below.
  #
  # Both requires are pcall'd. ../default.nix enables these plugins with
  # mkDefault, so a host can turn either one off independently and this code
  # still has to work.
  helpers = ''
    -- The claude terminal's window in the current tabpage, or nil if the
    -- terminal is hidden or was never started. The snacks provider keeps a
    -- hidden terminal's buffer valid, so get_active_terminal_bufnr() alone
    -- cannot tell "hidden" from "visible"; the window lookup can.
    local function claude_win()
      local ok, terminal = pcall(require, "claudecode.terminal")
      if not ok then
        return nil
      end
      local bufnr = terminal.get_active_terminal_bufnr()
      if not bufnr then
        return nil
      end
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
          return win
        end
      end
      return nil
    end

    -- Size the claude split from the *current* editor width. Snacks marks the
    -- split 'winfixwidth', so when the terminal (or the tmux pane holding it)
    -- grows, neovim hands every new column to the code buffer and claude stays
    -- at whatever width it was opened at. Snacks only re-fits floating windows
    -- on VimResized, splits are left alone, so this does the equivalent for the
    -- split: the configured fraction of the editor, floored at minWidth.
    --
    -- nvim_win_set_width takes the columns from the windows that are not
    -- 'winfixwidth' first, which is the code buffer, so an open nvim-tree keeps
    -- its 30 columns unless there is nothing else left to shrink.
    local function fit_claude()
      local win = claude_win()
      if not win then
        return
      end
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        return -- a float: snacks owns that geometry
      end
      local want = math.max(math.floor(vim.o.columns * ${toString splitWidthPercentage}), ${toString minWidth})
      if vim.api.nvim_win_get_width(win) ~= want then
        vim.api.nvim_win_set_width(win, want)
      end
    end
  '';

  # The claude terminal opens as a vertical split (see splitWidthPercentage
  # above). With nvim-tree also up that leaves the file buffer squeezed into a
  # third column, so the tree goes away on the way in.
  #
  # Only when claude is about to *appear*: both commands are toggles, and
  # dropping the tree as a side effect of hiding claude would be surprising.
  #
  # Closing the tree *before* the command, not after, keeps the split arithmetic
  # honest: claude then sizes itself against the full-width editor instead of
  # against a layout that is about to lose a 30-column window.
  closeTreeThen = cmd: ''
    function()
      ${helpers}

      if not claude_win() then
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

  autoCmd = [
    {
      # Entering the claude window by any route (<C-l> through tmux-navigator,
      # a mouse click, <leader>cc) drops the tree. The tree sits on the far left
      # and claude on the far right, so with claude focused the tree is three
      # windows of layout away from where the attention is, and its 30 columns
      # go back to the code buffer (claude's 'winfixwidth' keeps them off it).
      event = [ "WinEnter" ];
      desc = "Close nvim-tree when the Claude Code window is entered";
      callback.__raw = ''
        function()
          ${helpers}
          if vim.api.nvim_get_current_win() ~= claude_win() then
            return
          end
          local tree_ok, tree = pcall(require, "nvim-tree.api")
          if tree_ok and tree.tree.is_visible() then
            tree.tree.close()
          end
        end
      '';
    }
    {
      # The tmux pane holding neovim grows (zoom, a sibling pane closing, the
      # window being focused by a layout that enlarges it) or shrinks.
      event = [ "VimResized" ];
      desc = "Keep the Claude Code split at its configured share of the editor";
      callback.__raw = ''
        function()
          ${helpers}
          fit_claude()
        end
      '';
    }
    {
      # The terminal buffer lands in a window: first open through snacks, or a
      # re-show after :ClaudeCode hid it. Both paths size the split as a plain
      # fraction of the editor with no floor, so apply minWidth after them.
      #
      # Scheduled, for two reasons. Snacks opens with `sbuffer N | vertical
      # resize W` and BufWinEnter fires between those two, so a synchronous fit
      # would be overwritten. And on the first open the provider only records
      # the terminal after Snacks returns, so fit_claude() cannot find it until
      # the next tick. That is also why this does not filter on the claude
      # buffer here: fit_claude() is a no-op for any other terminal.
      event = [ "BufWinEnter" ];
      pattern = [ "term://*" ];
      desc = "Apply the Claude Code split's minimum width on open";
      callback.__raw = ''
        function()
          ${helpers}
          vim.schedule(fit_claude)
        end
      '';
    }
  ];

  plugins.snacks = {
    enable = lib.mkDefault true;
  };
  # The claudecode plugin declares claude-code as a nixvim dependency, which
  # *prefixes* the wrapper's PATH with stable's claude-code. That shadows the
  # unstable one home-manager puts in the user profile (see
  # ../../home/programs/claude-code.nix), so :ClaudeCode ran a release behind
  # the terminal. Pin the dependency to the same unstable package.
  dependencies.claude-code.package = unstable.claude-code;

  plugins.claudecode = {
    enable = lib.mkDefault true;
    # nixos-26.05 froze claudecode.nvim at 2026-04-27, two months before
    # `diff_opts.layout = "unified"` landed upstream. Passing "unified" to the
    # frozen plugin trips an assert in its setup(), which aborts the rest of
    # init.lua, so this one plugin tracks unstable.
    package = unstable.vimPlugins.claudecode-nvim;
    settings = {
      # claude sees $TMUX and wraps its OSC 52 copy in tmux's DCS passthrough.
      # The outer terminal here is neovim's, not tmux, and it does not unwrap
      # that, so the base64 payload leaked into the prompt as "52;c;...". Blank
      # it so claude sends plain OSC 52 (it still copies through wl-copy as
      # well). This is a top-level key: under `terminal` it is rejected.
      env = {
        TMUX = "";
      };
      diff_opts = {
        # single buffer with deleted lines inline, VS Code style
        layout = "unified";
        keep_terminal_focus = true;
      };
      terminal = {
        provider = "snacks";
        split_width_percentage = splitWidthPercentage;
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
