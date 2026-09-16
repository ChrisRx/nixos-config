# Declarations for the `packages.<category>.enable` flags.
#
# Kept separate from ./default.nix so that modules/nixos/core can declare the
# same options without importing the home module: that import had to be a bare
# function call, which forced every argument in ./default.nix to carry a
# default it never actually used.
{ lib }:
builtins.listToAttrs (
  map
    (
      name:
      lib.nameValuePair name {
        enable = lib.mkEnableOption "Enable ${name} packages";
      }
    )
    [
      # categories
      "all"
      "cloud"
      "development"
      "experimental"
      "extra"
      "fonts"
      "utils"
    ]
)
