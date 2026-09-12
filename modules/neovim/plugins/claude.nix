{ ... }: {
  keymaps = [{
    mode = [ "n" ];
    key = "<leader>cc";
    action = "<cmd>ClaudeCode<cr>";
    options = { noremap = true; };
  }];
  plugins.claude-code = { enable = true; };
}
