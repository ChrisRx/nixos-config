{ pkgs, ... }: {
  programs.nixvim = {
    keymaps = [
      {
        mode = [ "n" ];
        key = "<leader>f";
        action = "<cmd>NvimTreeFindFile<cr>";
        options = { nowait = true; };
      }
      {
        mode = [ "n" ];
        key = "<C-n>";
        action = "<cmd>NvimTreeToggle<cr>";
        options = { nowait = true; };
      }
    ];
    plugins.treesitter = {
      enable = true;
      nixGrammars = true;
      settings = {
        highlight = {
          enable = true;
          use_languagetree = true;
        };
        indent.enable = true;
      };
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash
        c
        css
        git_config
        gitcommit
        gitignore
        go
        gomod
        gosum
        gowork
        graphql
        helm
        html
        javascript
        json
        lua
        make
        markdown
        nginx
        nix
        proto
        python
        regex
        rust
        scala
        templ
        terraform
        tmux
        toml
        typescript
        vim
        vimdoc
        xml
        yaml
        zig
      ];
    };
  };
}
