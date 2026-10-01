{ pkgs, lib, ... }: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    installVimSyntax = true;
    settings = {
      background-opacity = 0.85;
      maximize = true;
      window-decoration = false;
      font-size = 8.5;
      background = "#101010";
      cursor-style = "block";
      mouse-hide-while-typing = true;
      shell-integration-features = "no-cursor";

      # Same binding as ./alacritty.nix: ctrl+enter sends ESC then M instead
      # of a bare CR. ghostty's `esc:M` is the literal equivalent of
      # alacritty's `chars = "\\u001bM"`. A list renders as repeated
      # `keybind = …` lines, which is how ghostty takes more than one.
      keybind = [ "ctrl+enter=esc:M" ];
    };
  };

  # Reload ghostty on NixOS rebuild
  xdg.configFile."ghostty/config".onChange = lib.mkAfter ''
    ${pkgs.procps}/bin/pkill -USR2 ghostty || true
  '';
}
