{ config, pkgs, ... }:
{
  imports = [
    ./programs/alacritty.nix
    ./programs/git.nix
    ./programs/neovim.nix
    ./programs/tmux.nix
    ./programs/zsh.nix
  ];

  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      config = {
        whitelist = {
          prefix = [ "~/src/ChrisRx" ];
        };
      };
    };

    ripgrep = {
      enable = true;
      arguments = [
        # Don't let ripgrep vomit really long lines to my terminal.
        "--max-columns=150"
        "--max-columns-preview"

        # Add my 'web' type.
        "--type-add"
        "web:*.{html,css,js}*"

        # Exclude directories
        "--glob=!git/*"
        "--glob=!vendor/*"

        # Set the colors.
        "--colors=line:none"
        "--colors=line:style:bold"
        "--colors=path:fg:yellow"
        "--colors=match:fg:125"
      ];
    };

    eza = {
      enable = true;
      git = true;
      enableZshIntegration = true;
      icons = "auto";
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        kubernetes.disabled = false;
        nix_shell = {
          impure_msg = "[impure](bold red)";
          pure_msg = "[pure](bold green)";
          unknown_msg = "[unknown shell](bold yellow)";
          format = "via [❄️ $state( \($name\))](bold blue) ";
        };
        golang = {
          symbol = " ";
        };
      };
    };

    yazi = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
