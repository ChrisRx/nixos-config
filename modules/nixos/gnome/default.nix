{ pkgs, ... }: {
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.desktopManager.gnome.sessionPath = [ pkgs.mutter ];

  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnome-tweaks
    gnome-monitor-config
  ];

  environment.gnome.excludePackages = with pkgs; [
    gnome-calculator
    gnome-console
    gnome-clocks
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-text-editor
    gnome-tour
    gnome-user-docs
    gnome-weather
    simple-scan
  ];

  programs.dconf.profiles.user.databases = [{
    lockAll = true; # prevents overriding
    settings = {
      "org/gnome/desktop/input-sources" = {
        xkb-options = [ "caps:ctrl_modifier" ];
      };
    };
  }];
}
