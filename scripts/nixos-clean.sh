#/bin/sh

nix-collect-garbage
nix-collect-garbage -d
# nix-store --optimize
sudo nix-collect-garbage -d
sudo nixos-rebuild switch --upgrade --impure --flake . -v
