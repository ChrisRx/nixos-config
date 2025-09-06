{ config, pkgs, ... }:
{
  programs.firefox.enable = true;
  programs.zsh.enable = true;

  # steam
  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  # necessary?
  hardware.xpadneo.enable = true;
  environment.systemPackages = [ pkgs.steam-devices-udev-rules ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    acl
    attr
    bzip2
    curl
    libsodium
    libssh
    libxkbcommon
    libxml2
    openssl
    stdenv.cc.cc
    stdenv.cc.cc.lib
    systemd
    util-linux
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libxcb
    xz
    zlib
    zstd
  ];
}
