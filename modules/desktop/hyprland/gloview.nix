# github.com/fedsfarm/gloview — a macOS Mission Control-style overview: every
# window on the workspace laid out as a live, scaled-down preview.
#
# Upstream *does* ship a flake, which is what this tree used to take the plugin
# from. It is packaged in-tree anyway, because that flake output builds against
# its own patched compositor rather than the one the session runs:
#
#   hyprlandPkg = hyprland.packages.${system}.hyprland.overrideAttrs (old: {
#     postPatch = (old.postPatch or "") + ''
#       substituteInPlace CMakeLists.txt --replace-fail "glaze 7...<8" "glaze"
#     '';
#   });
#
# overrideAttrs changes the derivation hash, so realising it compiles the whole
# compositor locally, and the plugin it produces targets that build instead of
# nixpkgs'. Nothing can reach that from the outside: it is internal to
# gloview's flake, which is why the input is `flake = false` and only its
# source is used.
#
# The patch works around Hyprland's own glaze version check in the upstream
# flake's dependency pin. nixpkgs-unstable already builds its hyprland with a
# glaze it accepts, so building against `unstable.hyprland` needs none of it:
# the compositor is a cache.nixos.org hit and the plugin targets the same
# build the session runs, the arrangement ./hypr-kinetic-scroll.nix has too.
{
  lib,
  cmake,
  pkg-config,
  hyprland,
  src,
}:

# `hyprland.stdenv`, not the ambient one, for the same reason as the other two:
# a plugin is dlopen'd into the compositor's address space, so it has to come
# from the toolchain that built the compositor. This is also what upstream's
# flake got via nixpkgs' mkHyprlandPlugin, which is `lib.extendMkDerivation`
# over `hyprland.stdenv.mkDerivation` and adds pkg-config, hyprland and
# hyprland.buildInputs — all spelled out below instead.
hyprland.stdenv.mkDerivation {
  pname = "gloview";

  # 0.3.0 is what upstream's CMakeLists and flake both declare, but the input
  # in ../../../flake.nix names no ref and so tracks the default branch: the
  # version is stale the moment `nix flake update` moves the rev. Hence
  # nixpkgs' `<version>-unstable-<date>` spelling, off the input's own
  # lastModifiedDate.
  version = "0.3.0-unstable-${lib.concatStringsSep "-" (builtins.match "(....)(..)(..).*" src.lastModifiedDate)}";

  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  # pkg_check_modules asks for hyprland and glesv2, pkg_search_module for lua,
  # and CMakeLists adds `include/hyprland/src` off hyprland's own include dirs
  # for the compositor headers the sources include directly. All three come out
  # of hyprland: its `dev` output carries hyprland.pc (chooseDevOutputs picks
  # that off the derivation below), libglvnd in its buildInputs carries
  # glesv2.pc, and so does lua.
  #
  # Upstream's flake adds pkgs.luajit here as well, on the grounds that luajit
  # is what Hyprland links. Here it is not, and the extra input does
  # nothing: pkg_search_module(LUA REQUIRED lua lua5.4 lua-5.4 lua54 luajit)
  # resolves by module name in the order listed, `lua` hits hyprland's own
  # lua 5.5 first, and the built .so references lua-5.5.0 with or without it.
  # Leaving it out is the point rather than tidiness — the plugin runs inside
  # the compositor's lua state, so a second lua runtime in that address space
  # is the failure mode to stay away from.
  buildInputs = [ hyprland ] ++ hyprland.buildInputs;

  # Upstream has an `install(TARGETS gloview LIBRARY ...)` rule, so unlike the
  # other two plugins here the default cmake installPhase does the work and
  # lands $out/lib/gloview.so. The target sets PREFIX "" to get that name,
  # which is not the lib<name>.so convention nixpkgs' hyprland plugins follow
  # and ./home.nix links into ~/.config/hypr/plugins, hence the symlink.
  postInstall = ''
    ln -s gloview.so "$out/lib/libgloview.so"
  '';

  meta = {
    description = "macOS Mission Control-style overview for Hyprland";
    homepage = "https://github.com/fedsfarm/gloview";
    license = lib.licenses.gpl3Plus;
    platforms = hyprland.meta.platforms;
  };
}
