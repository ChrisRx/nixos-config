{ config, lib, username, ... }:

let cfg = config.core;
in {
  imports =
    [ ./boot.nix ./networking.nix ./programs.nix ./system.nix ./user.nix ];
  options.core = {
    user = {
      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "";
      };
    };
  };

  config = { users.users.${username}.extraGroups = cfg.user.extraGroups; };
}
