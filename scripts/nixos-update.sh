#!/bin/sh

sudo nix flake update -v
sudo nixos-rebuild switch --upgrade --impure --flake . -v
