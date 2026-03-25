{ config, lib, pkgs, ... }:

let cfg = config.steam;
in {
  options.steam = { enable = lib.mkEnableOption "Enable steam"; };

  config = lib.mkIf cfg.enable {
    programs.steam.enable = true;
    hardware.steam-hardware.enable = true;
    hardware.xone.enable = true;
    environment.systemPackages = with pkgs; [ steam-devices-udev-rules ];
  };
}
