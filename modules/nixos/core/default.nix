{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.core;
in
{
  imports = [
    ./boot.nix
    ./kernel.nix
    ./networking.nix
    ./programs.nix
    ./system.nix
    ./user.nix
    ../../desktop
    ../nvidia
    ../steam
  ];
  options.core = {
    user = {
      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "";
      };
    };
    packages = import ../../home/packages-options.nix { inherit lib; };

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
