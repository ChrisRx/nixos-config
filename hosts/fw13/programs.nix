{ pkgs, ... }: {
  programs.firefox.enable = true;
  programs.zsh.enable = true;

  # steam
  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  environment.systemPackages = [ pkgs.steam-devices-udev-rules ];
  hardware.xpadneo.enable =
    true; # necessary? need to test that bt with steam still works

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    acl
    attr
    bzip2
    curl
    gcc
    libgcc
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
