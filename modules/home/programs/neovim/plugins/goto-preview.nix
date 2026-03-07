{ ... }: {
  programs.nixvim = {
    keymaps = [{
      mode = [ "n" ];
      key = "<leader>gd";
      action = "<cmd>lua require('goto-preview').goto_preview_definition()<cr>";
      options = { noremap = true; };
    }];
    plugins = {
      goto-preview = {
        enable = true;
        settings = {
          width = 120;
          height = 30;
          post_open_hook = {
            __raw = ''
              function(buf, _)
                vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { silent = true, nowait = true, noremap = true })
              end
            '';
          };
        };
      };
    };
  };
}

# nnoremap gpd <cmd>lua require('goto-preview').goto_preview_definition()<CR>
# nnoremap gpt <cmd>lua require('goto-preview').goto_preview_type_definition()<CR>
# nnoremap gpi <cmd>lua require('goto-preview').goto_preview_implementation()<CR>
# nnoremap gpD <cmd>lua require('goto-preview').goto_preview_declaration()<CR>
# nnoremap gP <cmd>lua require('goto-preview').close_all_win()<CR>
# nnoremap gpr <cmd>lua require('goto-preview').goto_preview_references()<CR>
