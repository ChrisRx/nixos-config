{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.desktop.hyprland;

  hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      # Use the flake inputs hyprland package so that plugins build and load
      # correctly.
      package = hyprland.hyprland;
      # The portal is pinned alongside it deliberately: it is versioned in
      # lockstep with the compositor upstream, and leaving it on nixpkgs' build
      # pairs a 0.55.4 portal with a 0.56.0 session.
      portalPackage = hyprland.xdg-desktop-portal-hyprland;
    };
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.hyprland.enableGnomeKeyring = true;
    # TODO: Figure out why this isn't working. It is still asking to unlock the
    # keyring after login.
    security.pam.services.gdm.enableGnomeKeyring = true; # load gnome-keyring at startup
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
