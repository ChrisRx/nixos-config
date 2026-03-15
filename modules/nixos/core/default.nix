{ config, pkgs, lib, username, ... }:

let cfg = config.core;
in {
  imports =
    [ ./boot.nix ./networking.nix ./programs.nix ./system.nix ./user.nix ];
  options.core = {
    user = {
      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "";
      };
    };
    packages =
      (import ../../home { inherit pkgs config lib; }).options.packages;

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.git ]";
      description = ''
        Additional home-manager packages to be included.
      '';
    };
  };

  config = {
    users.users.${username}.extraGroups = cfg.user.extraGroups;
    home-manager.users.${username} = {
      packages = cfg.packages;
      home.packages = cfg.extraPackages;
    };
  };
}
