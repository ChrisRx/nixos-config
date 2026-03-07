{ ... }: {
  programs.nixvim = {
    keymaps = [
      {
        mode = [ "n" ];
        key = "<leader>f";
        action = "<cmd>NvimTreeFindFile<cr>";
        options = {
          # nowait = true;
        };
      }
      {
        mode = [ "n" ];
        key = "<C-n>";
        action = "<cmd>NvimTreeToggle<cr>";
        options = { nowait = true; };
      }
    ];

    highlight = { BufferCurrentSign.fg = "white"; };

    plugins.nvim-tree = {
      enable = true;

      settings = {
        auto_reload_on_write = true;
        disable_netrw = true;
        filters = { dotfiles = false; };
        git.enable = false;
        hijack_cursor = true;
        renderer = {
          root_folder_label = false;
          highlight_git = true;
          indent_markers = { enable = true; };
          icons = {
            glyphs = {
              default = "󰈚";
              folder = {
                default = "";
                empty = "";
                empty_open = "";
                open = "";
                symlink = "";
              };
              git = { unmerged = ""; };
            };
          };
        };
        open_on_setup_file = true;
        sync_root_with_cwd = true;
        update_focused_file = {
          enable = true;
          update_root = false;
        };
        view = {
          width = 30;
          preserve_window_proportions = true;
        };
      };

    };
  };
}
