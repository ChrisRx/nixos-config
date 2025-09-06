{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      gcc
      cmake
      gnumake
      fzf
    ];
  };
}
