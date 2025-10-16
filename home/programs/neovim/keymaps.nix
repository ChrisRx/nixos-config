{ ... }: {
  programs.nixvim = {
    globals = { mapleader = ","; };

    keymaps = [
      {
        mode = [ "i" ];
        key = "jk";
        action = "<ESC>";
        options = { nowait = true; };
      }
      {
        mode = [ "n" ];
        key = ";";
        action = ":";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "m";
        action = ":";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "M";
        action = ",";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "<C-h>";
        action = "<cmd>TmuxNavigateLeft<cr>";
      }
      {
        mode = [ "n" ];
        key = "<C-j>";
        action = "<cmd>TmuxNavigateDown<cr>";
      }
      {
        mode = [ "n" ];
        key = "<C-k>";
        action = "<cmd>TmuxNavigateUp<cr>";
      }
      {
        mode = [ "n" ];
        key = "<C-l>";
        action = "<cmd>TmuxNavigateRight<cr>";
      }
      {
        mode = [ "n" ];
        key = "<leader>/";
        action.__raw = ''
          function()
            require("Comment.api").toggle.linewise.current()
          end
        '';
      }
      {
        mode = [ "v" ];
        key = "<leader>/";
        action =
          "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>";
      }
      {
        mode = [ "n" ];
        key = "H";
        action = "^";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "L";
        action = "$";
        options = { noremap = true; };
      }
      {
        mode = [ "v" ];
        key = "H";
        action = "^";
        options = { noremap = true; };
      }
      {
        mode = [ "v" ];
        key = "L";
        action = "$";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "<leader>cz";
        action =
          "yy<cmd>lua require('Comment.api').toggle.linewise.current()<CR>p";
        options = { noremap = true; };
      }
      {
        mode = [ "v" ];
        key = "<leader>cz";
        action =
          "Y`><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>p";
        options = { noremap = true; };
      }
      {
        mode = [ "n" ];
        key = "<cr>";
        action = ":nohl<cr><cr>";
        options = {
          desc = "redraw screen to remove highlighting";
          silent = true;
        };
      }
      {
        mode = [ "n" ];
        key = "S";
        action = "i<Enter><Esc>^";
        options = { desc = "Split line"; };
      }
      {
        mode = [ "x" "n" ];
        key = "j";
        action = ''v:count || mode(1)[0:1] == "no" ? "j" : "gj"'';
        options = {
          desc = "Move down";
          expr = true;
        };
      }
      {
        mode = [ "x" "n" ];
        key = "k";
        action = ''v:count || mode(1)[0:1] == "no" ? "k" : "gk"'';
        options = {
          desc = "Move up";
          expr = true;
        };
      }
      {
        mode = [ "n" ];
        key = "<leader>lf";
        action.__raw = ''
          function()
            vim.diagnostic.open_float { border = "rounded" }
          end
        '';
        options = { desc = "Floating diagnostic"; };
      }
      {
        mode = [ "n" ];
        key = "<leader>fm";
        action.__raw = ''
          function()
            vim.lsp.buf.format { async = true }
          end
        '';
        options = { desc = "LSP formatting"; };
      }
      {
        mode = [ "i" ];
        key = "<leader>e";
        action = "<cmd>lua require('luasnip').expand()<cr>";
        options = { desc = "Expand snippet"; };
      }
      # {
      #   mode = "n";
      #   key = "<tab>";
      #   action = "<cmd>tabnext<cr>";
      #   options.desc = "Go to the sub-sequent tab";
      # }
      # {
      #   mode = "n";
      #   key = "<S-tab>";
      #   action = "<cmd>tabprevious<cr>";
      #   options.desc = "Go to the previous tab";
      # }
    ];

    # vim.keymap.set({"i"}, "<C-K>", function() ls.expand() end, {silent = true})
    # x = {
    #   -- Don't copy the replaced text after pasting in visual mode
    #   -- https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text#Alternative_mapping_for_paste
    #   ["p"] = { 'p:let @+=@0<CR>:let @"=@0<CR>', "Dont copy replaced text", opts = { silent = true } },
    # },
  };
}
