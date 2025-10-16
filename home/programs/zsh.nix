{ config, pkgs, ... }: {
  home.sessionVariables = {
    HISTSIZE = 10000;
    SAVEHIST = 10000;
  };
  home.shell.enableZshIntegration = true;
  home.file = { ".zshrc.extra".source = ../files/zshrc.extra; };
  programs.zsh = {
    enable = true;

    autosuggestion = { enable = true; };

    enableCompletion = true;
    completionInit = ''
      autoload -U compinit
      zstyle ':completion:*' menu select
      zmodload zsh/complist
      compinit

      # Include hidden files in autocomplete:
      _comp_options+=(globdots)
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [
        "archlinux"
        "aws"
        "colored-man-pages"
        "git"
        "history-substring-search"
        "kubectl"
        "vi-mode"
        "zsh-navigation-tools"
        "gcloud"
      ];
    };
    syntaxHighlighting = { enable = true; };
    sessionVariables = { SOMETHING = "OMG"; };
    initContent = ''
      source $HOME/.zshrc.extra
    '';
  };
}
