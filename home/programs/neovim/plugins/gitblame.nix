{ ... }: {
  programs.nixvim = {
    keymaps = [{
      mode = [ "n" ];
      key = "<leader>gb";
      action = "<cmd>GitBlameToggle<cr>";
      options = { noremap = true; };
    }];
    plugins = {
      gitblame = {
        enable = true;
        settings = { enabled = false; };
      };
    };
  };
}
