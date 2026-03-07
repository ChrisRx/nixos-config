{ ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
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
