{
  pkgs,
  unstable ? pkgs,
  ...
}:
{
  imports = [
    ./alacritty.nix
    ./git.nix
    ./tmux.nix
    ./zsh.nix
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
        hide_env_diff = true;
      };
    };
    claude-code = {
      enable = true;
      package = unstable.claude-code;
      settings = {
        theme = "dark";
        model = "opus";
        spinnerVerbs = {
          mode = "replace";
          verbs = [
            "Burning down old-growth forest"
            "10x-ing carbon emissions"
          ];
        };
        sandbox = {
          filesystem = {
            disabled = true;
          };
        };
        enabledPlugins = {
          "gopls-lsp@claude-plugins-official" = true;
        };
        permissions = {
          disableAutoMode = "disable";
          allow = [
            "Bash(git diff:*)"
          ];
          deny = [
            "WebFetch"
            "Read(./.env)"
          ];
        };
        hooks = {
          PostToolUse = [
            {
              hooks = [
                {
                  command = "[ -n \"$NVIM\" ] && nvim --server $NVIM --remote-expr 'execute(\"checktime\")'";
                  type = "command";
                }
              ];
              matcher = "Edit|MultiEdit|Write";
            }
          ];
        };
      };
    };

    ghostty = {
      enable = true;
      enableZshIntegration = true;
      installVimSyntax = true;
      settings = {
        background-opacity = 0.8;
        maximize = true;
        window-decoration = false;
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
