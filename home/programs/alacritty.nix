{ config, pkgs, ... }: {
  home.file = {
    # ".config/alacritty/catppuccin_macchiato.yaml".source = ../files/catppuccin_macchiato.yaml;
  };

  programs.alacritty = {
    enable = true;
    settings = {
      general.import = [
        # "~/.config/alacritty/themes/catpuccin_mocha.yaml"
      ];
      env.term = "xterm-256color";
      window = {
        opacity = 0.85;
        startup_mode = "Maximized";
        decorations = "None";
      };
      keyboard.bindings = [{
        chars = "\\u001bM";
        key = "Return";
        mods = "Control";
      }];
      scrolling.history = 50000;
      font = {
        size = 8.5;
        normal = {
          family = "FiraCode Nerd Font Mono";
          style = "Regular";
        };
      };
      colors = {
        # #303030
        # #8090fb
        # #503080
        # primary.background = "0x282C34";
        # primary.background = "0x303030";
        primary.background = "0x101010";
        cursor = {
          text = "0x212121";
          cursor = "0xc0c5ce";
        };
      };
      mouse.hide_when_typing = true;
    };
  };
}
