{ pkgs, ... }:
{
  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.xone.enable = true;
  environment.systemPackages = with pkgs; [
    steam-devices-udev-rules
  ];
}
