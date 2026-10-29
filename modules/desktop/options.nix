# Declarations for the `desktop.<name>.*` options.
#
# Both halves of a desktop environment are gated on the same flag, but they are
# evaluated by two different module systems: ./default.nix declares these on the
# NixOS side and forwards the evaluated tree into home-manager, ./home.nix
# declares them again on the home side so the home halves can read them. Keeping
# the declarations here is what keeps the two in sync; it follows
# ../home/packages-options.nix, which solves the same problem for
# `packages.<category>.enable`.
#
# Only options a desktop module needs to branch on, or that both halves need,
# belong here. Anything that is purely home-manager configuration is better set
# directly on the host, e.g.
#
#   home-manager.users.chris.programs.noctalia.settings.theme.mode = "light";
#
# which works because home-manager is evaluated as a NixOS module (see
# ../nixos/core/user.nix).
{ lib }:
{
  cosmic = {
    enable = lib.mkEnableOption "Enable cosmic desktop environment";
  };

  gnome = {
    enable = lib.mkEnableOption "Enable gnome desktop environment";
  };

  hyprland = {
    enable = lib.mkEnableOption "Enable hyprland desktop environment";

    mutableConfig = lib.mkEnableOption ''
      live editing of hyprland's lua config.

      ../desktop/hyprland/hyprland.lua is the config either way. Off, it is
      copied into the store like any other managed file; on,
      {file}`~/.config/hypr/hyprland.lua` is symlinked at
      {option}`desktop.hyprland.mutableConfigPath` instead, so saves apply on
      the next `hyprctl reload` rather than on the next rebuild.

      Meant to be flipped on while iterating and back off when done. Nothing
      needs copying in either direction: it is the same file
    '';

    mutableConfigPath = lib.mkOption {
      # A string, not a path: a nix path would be copied into the store, which
      # is the opposite of the point.
      type = lib.types.str;
      default = "/etc/nixos/nixos-config/modules/desktop/hyprland/hyprland.lua";
      description = ''
        Absolute path the live symlink points at while
        {option}`desktop.hyprland.mutableConfig` is set. Defaults to the same
        file the sealed mode copies, so edits made live are already in the
        working tree; point it at a scratch file instead to keep the repo copy
        clean until the good parts are merged back by hand.
      '';
    };

    # One flag per compositor plugin, all off: each is built from source
    # against the exact compositor, so an importer opts into the build cost and
    # the breakage risk per plugin. Read on the home side, which skips the build
    # and the ~/.config/hypr/plugins link, and from ../desktop/hyprland/plugins.lua
    # through the generated enabled_plugins.lua, so the lua follows these in
    # either mutableConfig mode.
    plugins = {
      gloview.enable = lib.mkEnableOption "the gloview workspace overview plugin";
      kineticScroll.enable = lib.mkEnableOption "the hypr-kinetic-scroll plugin";
      hyprWorld.enable = lib.mkEnableOption "the hypr-world plugin and app";
    };
  };
}
