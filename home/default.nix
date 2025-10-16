{ ... }: {
  imports = [ ./packages.nix ./programs ];

  home.username = "chris";
  home.homeDirectory = "/home/chris";
  home.stateVersion = "24.11";
  home.sessionVariables = {
    HISTSIZE = 10000;
    SAVEHIST = 10000;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
