{ pkgs, ... }:
{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.firefox.enable = true;
  programs.zsh.enable = true;

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
    libcap_ng
    openssl
    stdenv.cc.cc
    stdenv.cc.cc.lib
    systemd
    util-linux
    libx11
    libxcursor
    libxi
    libxcb
    xz
    zlib
    zstd
  ];
}
