{ ... }: {
  programs.nixvim = {
    keymaps = [
      {
        mode = [ "n" ];
        key = "<tab>";
        action = "<cmd>BufferNext<cr>";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "<s-tab>";
        action = "<cmd>BufferPrevious<cr>";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "<leader>x";
        action = "<cmd>BufferClose<cr>";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "<leader>xa";
        action = "<cmd>BufferCloseAllButCurrentOrPinned<cr>";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "<leader>s"; # do telescope
        action = "<cmd>b#<cr>";
        options = { noremap = true; };
      }
    ];
    highlight = { BufferCurrentSign.fg = "white"; };
    opts = { fillchars = { vert = "▎"; }; };
    plugins.barbar = {
      enable = true;
      settings = {
        maximum_padding = 0;
        minimum_padding = 0;
        sidebar_filetypes = { NvimTree = true; };
      };
    };
  };
}
