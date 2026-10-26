{ lib, ... }:
{
  # Needs catppuccin's home module imported alongside; homeModules.rofi in
  # ../../../flake.nix brings it in for importers that do not take
  # homeModules.default.
  #
  # A port only applies under the global `catppuccin.enable`, which
  # ./default.nix sets with autoEnable off. Repeated here as defaults so rofi
  # imported on its own is still themed, and with autoEnable off nothing else
  # the importer has gets catppuccin'd along with it.
  catppuccin = {
    enable = lib.mkDefault true;
    autoEnable = lib.mkDefault false;

    rofi = {
      enable = true;
      flavor = "mocha";
    };
  };

  programs.rofi = {
    enable = true;
    extraConfig = {
      modi = "drun";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      disable-history = false;
      hide-scrollbar = true;
      display-drun = "❯ ";
      sidebar-mode = true;
    };
  };
}
