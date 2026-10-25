# github.com/savonovv/hypr-kinetic-scroll — touchpad momentum scrolling done in
# the compositor, so it applies to every client and not just the browsers that
# implement it themselves.
#
# Upstream ships no flake and is not in nixpkgs, so this is the packaging. It is
# a plain `make`-based plugin: two translation units, one PKG_CONFIG line, and a
# .so dropped next to the sources.
{
  lib,
  pkg-config,
  hyprland,
  src,
}:

# `hyprland.stdenv`, not the ambient one. A plugin is dlopen'd into the
# compositor's own address space, so it has to be built by the toolchain that
# built the compositor: the `hyprland` flake input carries its own nixpkgs pin
# (see ../../../flake.nix), and compiling against its headers with a different
# gcc/libstdc++ than it was built with is how a plugin ends up failing at load
# on a missing CXXABI version rather than at build time.
hyprland.stdenv.mkDerivation {
  pname = "hypr-kinetic-scroll";

  # `src` is the flake input itself rather than a fetchFromGitHub call, so the
  # commit is pinned in flake.lock and moves with `nix flake update`. That also
  # makes the input's own lastModifiedDate the only version information there
  # is — upstream tags nothing and hardcodes "0.1" in PLUGIN_INIT — hence the
  # `0-unstable-<date>` spelling nixpkgs uses for unversioned sources.
  version = "0-unstable-${lib.concatStringsSep "-" (builtins.match "(....)(..)(..).*" src.lastModifiedDate)}";

  inherit src;

  # Adds `plugin:kinetic-scroll:stop_on_lift`, which is not an upstream option.
  # Everything upstream does is additive — it emits momentum after a lift — and
  # none of its eleven config keys touch the momentum *clients* generate for
  # themselves, which is the kind that survives `enabled = 0`. GTK, Chromium and
  # Firefox all start their own deceleration from wl_pointer.axis_stop, and
  # Hyprland derives that from the zero-delta event libinput ends a two-finger
  # scroll with (CSeatManager::sendPointerAxis, the `else if (value == 0)`
  # branch). The patch cancels that one event from the plugin's axis callback —
  # CInputManager::onMouseWheel returns before sending anything when a callback
  # cancels — and drops the plugin's own decay in the same breath, so a lift
  # stops the content dead. See ./plugins.lua for the option in use.
  #
  # Only the vertical axis_stop is withheld. sendPointerAxis sends one per axis
  # and libinput only emits a stop on the axes that scrolled, so the horizontal
  # one can be left alone — which it has to be, since that is the event a
  # browser commits or snaps back a two-finger back/forward swipe on.
  patches = [ ./hypr-kinetic-scroll-stop-on-lift.patch ];

  nativeBuildInputs = [ pkg-config ];

  # The Makefile's PKG_CONFIG line asks for pixman-1, libdrm, hyprland,
  # pangocairo, libinput, libudev, wayland-server and xkbcommon. Every one of
  # those is either hyprland's own .pc (its `dev` output, which chooseDevOutputs
  # picks off the derivation below) or something hyprland already builds
  # against, so taking its buildInputs wholesale is what satisfies them —
  # including lua 5.5, whose lua.h/lauxlib.h main.cpp includes directly and
  # which hyprland.pc does not list in `Requires`.
  buildInputs = [ hyprland ] ++ hyprland.buildInputs;

  # No installPhase upstream: `make all` leaves the .so in the source tree.
  # The lib<name>.so naming is nixpkgs' convention for hyprland plugins and is
  # what ./home.nix links into ~/.config/hypr/plugins.
  installPhase = ''
    runHook preInstall

    install -Dm444 hypr-kinetic-scroll.so $out/lib/libhypr-kinetic-scroll.so

    runHook postInstall
  '';

  meta = {
    description = "Kinetic (inertial) touchpad scrolling for Hyprland";
    homepage = "https://github.com/savonovv/hypr-kinetic-scroll";
    license = lib.licenses.mit;
    platforms = hyprland.meta.platforms;
  };
}
