{ pkgs, ... }: {
  programs.nixvim = {
    plugins.treesitter = {
      enable = true;
      nixGrammars = true;
      settings = {
        highlight = {
          enable = true;
          use_languagetree = true;
        };
        indent.enable = true;
        auto_install = false;
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
        #nix
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
