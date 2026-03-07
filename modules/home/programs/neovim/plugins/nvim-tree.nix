{ ... }:
{
  programs.nixvim = {
    keymaps = [
      {
        mode = [ "n" ];
        key = "<leader>f";
        action = "<cmd>NvimTreeFindFile<cr>";
        options = {
          nowait = true;
        };
      }
      {
        mode = [ "n" ];
        key = "<C-n>";
        action = "<cmd>NvimTreeToggle<cr>";
        options = {
          nowait = true;
        };
      }
    ];
    highlight = {
      BufferCurrentSign.fg = "white";
    };
    plugins.nvim-tree = {
      enable = true;
      openOnSetupFile = true;
      autoReloadOnWrite = true;
      filters = {
        dotfiles = false;
      };
      disableNetrw = true;
      hijackCursor = true;
      syncRootWithCwd = true;
      updateFocusedFile = {
        enable = true;
        updateRoot = false;
      };
      git.enable = false;
      view = {
        width = 30;
        preserveWindowProportions = true;
      };

      renderer = {
        rootFolderLabel = false;
        highlightGit = true;
        indentMarkers = {
          enable = true;
        };
        icons = {
          glyphs = {
            default = "󰈚";
            folder = {
              default = "";
              empty = "";
              emptyOpen = "";
              open = "";
              symlink = "";
            };
            git = {
              unmerged = "";
            };
          };
        };
      };
    };
  };
}
