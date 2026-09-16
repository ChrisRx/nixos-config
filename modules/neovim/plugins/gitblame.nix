{ lib, ... }: {
  keymaps = [{
    mode = [ "n" ];
    key = "<leader>gb";
    action = "<cmd>GitBlameToggle<cr>";
    options = { noremap = true; };
  }];
  plugins = {
    gitblame = {
      enable = lib.mkDefault true;
      settings = { enabled = false; };
    };
  };
}
