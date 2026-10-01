# home-manager half of the desktop environments.
#
# Imported by ../home/default.nix, so it is present under both the NixOS module
# (where ./default.nix defines `desktop`) and standalone home-manager (where
# nothing does, and every half stays disabled unless the importer sets the flag
# itself).
{ lib, ... }:

{
  imports = [
    ./hyprland/home.nix
  ];

  options.desktop = import ./options.nix { inherit lib; };
}
