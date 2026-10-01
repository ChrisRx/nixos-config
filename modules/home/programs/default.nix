{ ... }:
{
  imports = [
    ./alacritty.nix
    ./claude-code.nix
    ./ghostty.nix
    ./git.nix
    ./tmux.nix
    ./zsh.nix
  ];

  catppuccin = {
    enable = true;
    autoEnable = false;

    rofi = {
      enable = true;
      flavor = "mocha";
    };
  };

  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      config = {
        whitelist = {
          prefix = [ "~/src/ChrisRx" ];
        };
        hide_env_diff = true;
      };
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

    rofi = {
      enable = true;
      extraConfig = {
        modi = "drun";
        show-icons = true;
        drun-display-format = "{icon} {name}";
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "❯ ";
        sidebar-mode = true;
      };
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
          format = "via [❄️ $state( ($name))](bold blue) ";
        };
        golang = {
          symbol = " ";
        };
      };
    };

    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
      settings = {
        preview = {
          image_quality = 90;
          max_width = 8196;
          max_height = 4800;
        };
      };
    };
  };
}
