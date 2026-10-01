# NixOS half of the desktop environments.
#
# Each `<name>/nixos.nix` is gated on `desktop.<name>.enable`, so hosts pick a
# desktop with a single flag, and enabling more than one is allowed (fw13 runs
# gnome's greeter alongside a hyprland session).
{
  config,
  lib,
  username,
  ...
}:

{
  imports = [
    ./cosmic/nixos.nix
    ./gnome/nixos.nix
    ./hyprland/nixos.nix
  ];

  options.desktop = import ./options.nix { inherit lib; };

  # `imports` cannot be wrapped in `lib.mkIf`, so the home halves are always
  # imported (see ./home.nix) and gate themselves on the same flags. Forwarding
  # the evaluated tree is what makes those flags visible on the home side, the
  # same way core.packages reaches home-manager in ../nixos/core/default.nix.
  config.home-manager.users.${username}.desktop = config.desktop;
}
