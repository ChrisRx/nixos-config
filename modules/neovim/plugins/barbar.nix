{ ... }: {
  keymaps = [
    {
      mode = [ "n" ];
      key = "<tab>";
      action = "<cmd>BufferNext<cr>";
      options = {
        noremap = true;
      };
    }
    {
      mode = [ "n" ];
      key = "<s-tab>";
      action = "<cmd>BufferPrevious<cr>";
      options = {
        noremap = true;
      };
    }
    {
      mode = [ "n" ];
      key = "<leader>x";
      action = "<cmd>BufferClose<cr>";
      options = {
        noremap = true;
      };
    }
    {
      mode = [ "n" ];
      key = "<leader>xa";
      action = "<cmd>BufferCloseAllButCurrentOrPinned<cr>";
      options = {
        noremap = true;
      };
    }
    {
      mode = [ "n" ];
      key = "<leader>s";
      action = "<cmd>b#<cr>";
      options = {
        noremap = true;
      };
    }
  ];
  highlight = {
    BufferCurrentSign = {
      fg = "white";
      bg = "#313244";
      bold = true;
    };
    BufferCurrent = {
      fg = "white";
      bg = "#313244";
      bold = true;
    };
    BufferCurrentIndex = {
      fg = "white";
      bg = "#313244";
      bold = true;
    };
    BufferCurrentMod = {
      fg = "white";
      bg = "#313244";
      bold = true;
    };
    BufferCurrentTarget = {
      fg = "white";
      bg = "#313244";
      bold = true;
    };
    BufferCurrentIcon = {
      bg = "#313244";
    };
  };
  opts = {
    fillchars = {
      vert = "▎";
    };
  };
  plugins.barbar = {
    enable = true;
    settings = {
      exclude_name = [ "claude" ];
      maximum_padding = 0;
      minimum_padding = 0;
      sidebar_filetypes = {
        NvimTree = true;
      };
    };
  };
}
