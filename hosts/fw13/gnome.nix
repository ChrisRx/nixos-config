# TODO: put in module
{ config, pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    # Enable the GNOME Desktop Environment.
    udev.packages = [ pkgs.gnome-settings-daemon ];
  };
  environment.systemPackages = with pkgs; [
    pkgs.gnomeExtensions.appindicator
    gnome-tweaks
  ];
}
