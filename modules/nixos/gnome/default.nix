{ pkgs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Enable the GNOME Desktop Environment.
  services.udev.packages = [ pkgs.gnome-settings-daemon ];

  environment.systemPackages = with pkgs; [
    pkgs.gnomeExtensions.appindicator
    gnome-tweaks

    gnome-monitor-config
  ];
}
