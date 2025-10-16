{ ... }: {
  programs.nixvim = {
    highlight = {
      # keep
      BufferCurrentSign.fg = "white";
      # NvimTreeNormal.bg = "#282C34";
    };
    # highlightOverride = {
    #   # keep
    #   NvimTreeNormal = {
    #     # fg = "none";
    #     fg = "#282C34";
    #     # bg = "#282C34";
    #     bg = "none";
    #     blend = 50;
    #   };
    # };
    plugins.nvim-tree = {
      # extraConfigLuaPre = ''
      #   require('nvim-tree').setup({ sort = {
      #     sorter = "case_sensitive";
      #   }; })
      # '';
      # settings = {
      #
      # };
      enable = true;
      openOnSetupFile = true;
      autoReloadOnWrite = true;
      filters = { dotfiles = false; };
      disableNetrw = true;
      hijackCursor = true;
      syncRootWithCwd = true;
      updateFocusedFile = {
        enable = true;
        updateRoot = false;
      };

      # icons = { git_placement = "after"; };

      git.enable = false;
      view = {
        width = 30;
        preserveWindowProportions = true;
      };
      # sort = { sorter = "case_sensitive"; };
      renderer = {
        rootFolderLabel = false;
        highlightGit = true;
        indentMarkers = { enable = true; };
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
            git = { unmerged = ""; };
          };
        };
      };
    };
  };
}
