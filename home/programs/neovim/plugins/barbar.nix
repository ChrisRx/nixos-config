{ ... }: {
  programs.nixvim = {
    # keymaps = [
    #   {
    #     mode = [ "n" ];
    #     key = "<tab>";
    #     action = "<cmd>BufferLineCycleNext<cr>";
    #     options = { noremap = true; };
    #   }
    #   {
    #     mode = [ "n" ];
    #     key = "<s-tab>";
    #     action = "<cmd>BufferLineCyclePrev<cr>";
    #     options = { noremap = true; };
    #   }
    #   {
    #     mode = [ "n" ];
    #     key = "<leader>x";
    #     action = "<cmd>BufferLinePickClose<cr>";
    #     options = { noremap = true; };
    #   }
    # ];
    #
    # plugins.bufferline = {
    #   enable = true;
    #   settings = {
    #     options = {
    #       always_show_bufferline = true;
    #       # mode = "tabs";
    #       offsets = [{
    #         filetype = "NvimTree";
    #         highlight = "Directory";
    #         text = "File Explorer";
    #         text_align = "center";
    #       }];
    #
    #     };
    #   };
    # };
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
    highlight = {
      # keep
      BufferCurrentSign.fg = "white";
    };
    # maps.normal = {
    #   # Reordering tabs
    #   # "<m-s-j>" = "<cmd>BufferMoveNext<cr>";
    #   # "<m-s-k>" = "<cmd>BufferMovePrevious<cr>";
    #   # "<m-p>" = "<cmd>BufferPin<cr>";
    #
    #   # Navigating tabs
    #   "<tab>" = "<cmd>BufferNext<cr>";
    #   "<s-tab>" = "<cmd>BufferPrevious<cr>";
    #   # "<m-1>" = "<cmd>BufferGoto 1<cr>";
    #   # "<m-2>" = "<cmd>BufferGoto 2<cr>";
    #   # "<m-3>" = "<cmd>BufferGoto 3<cr>";
    #   # "<m-4>" = "<cmd>BufferGoto 4<cr>";
    #   # "<m-5>" = "<cmd>BufferGoto 5<cr>";
    #   # "<m-6>" = "<cmd>BufferGoto 6<cr>";
    #   # "<m-7>" = "<cmd>BufferGoto 7<cr>";
    #   # "<m-8>" = "<cmd>BufferGoto 8<cr>";
    #   # "<m-9>" = "<cmd>BufferGoto 9<cr>";
    #   "<leader>s" = "<cmd>BufferLast<cr>";
    #▎
    #   # Close tab
    #   "<leader>x" = "<cmd>BufferClose<cr>";
    # };
    # autoCmd = [{
    #   command = "echo 'Entering a C or C++ file'";
    #   event = [ "BufEnter" "BufWinEnter" ];
    #   pattern = [ "*.c" "*.h" ];
    # }];

    # :set fillchars+=vert:▕
    # :set fillchars+=vert:▕▎

    opts = { fillchars = { vert = "▎"; }; };

    plugins.barbar = {
      enable = true;
      # luaConfig.pre = ''
      #   vim.api.nvim_set_hl(0, 'BufferCurrentSign', guifg=red)
      # '';
      settings = {
        # tabpages = true;
        maximum_padding = 0;
        minimum_padding = 0;
        # separator = {
        #   left = "";
        #   right = "";
        # };
        # separator = {
        #   # left = "▎";
        #   left = "|";
        #   right = "";
        # };
        sidebar_filetypes = { NvimTree = true; };
      };
    };
  };
}
