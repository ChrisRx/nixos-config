# github.com/samine825/Hypr3D — renders the workspace as a walkable 3D room
# and puts the windows in it as textured quads.
#
# Upstream ships no flake and is not in nixpkgs, so this is the packaging. It
# is a cmake build of twelve translation units plus a vendored Jolt Physics
# tree under third_party/.
{
  lib,
  cmake,
  pkg-config,
  hyprland,
  src,
}:

# `hyprland.stdenv`, not the ambient one, for the same reason as
# ./hypr-kinetic-scroll.nix: a plugin is dlopen'd into the compositor's address
# space, so it has to come from the toolchain that built the compositor.
hyprland.stdenv.mkDerivation {
  pname = "hypr3d";

  # `src` is the flake input, whose url names a rev outright precisely so that
  # the patches below keep applying; see ../../../flake.nix for why, and bump it
  # there to move this. Upstream tags nothing, hence nixpkgs'
  # `0-unstable-<date>` spelling off the input's lastModifiedDate.
  version = "0-unstable-${lib.concatStringsSep "-" (builtins.match "(....)(..)(..).*" src.lastModifiedDate)}";

  inherit src;

  # Fixes the SIGSEGV on toggling the view back OFF, which takes the whole
  # compositor down (SIGSEGV in CMonitor::useFP16, from CHyprOpenGLImpl::end, in
  # the frame that was mid-flight).
  #
  # deactivate3D() ran straight from the RENDER_LAST_MOMENT callback, two
  # statements ahead of the compositor's own endRender(), and it unghosts every
  # window (a relayout), moves keyboard focus, restores the cursor and frees its
  # snapshot framebuffers. A nested render pass opened by any of that —
  # IHyprRenderer::makeSnapshotFB is the usual one — resets
  # m_renderData.pMonitor in its endRender(), and the outer endRender() then
  # dereferences that null monitor. The patch sets a flag instead and lets the
  # plugin's existing 8ms frame-pump timer run the teardown from the event loop,
  # outside any frame.
  #
  # Upstream already documents this exact failure in syncWorld() and moved
  # capture and ghosting to render.pre for it; the exit path was simply missed.
  #
  # The other three all come from one root cause: every new entity spawns at
  # the SAME pose, `camera + forward * spawn_distance` facing the camera, so
  # surfaces land exactly coincident and exactly coplanar. Window quads write
  # depth and test GL_LESS, and equal depth is not less, so whichever quad the
  # traversal emits first takes every overlapping pixel and the others are
  # rejected outright. That is the noctalia bar strobing in the middle of the
  # view, and it is also why a launcher opened on top of a window never showed
  # up at all.
  #
  # - bsp-back-polygon-order: a standalone upstream bug. bspBuild tests `!pos`
  #   before `!neg`, which is true both for a coplanar polygon and for one
  #   lying wholly behind the plane, so behind-only polygons were filed as
  #   coplanar and emitted outside the back subtree. Windows then hide each
  #   other depending on which side of the plane the player is standing on.
  # - spawn-offset-coincident: steps each new entity along the view axis out
  #   of a pose another entity already holds, newest nearest, which is the
  #   stacking the surfaces had in 2D.
  # - spawn-above-floor: the same depth rejection, but against the grid
  #   platform rather than another window. A quad is centred on the eye, so
  #   anything taller than twice the eye height hangs through the floor and
  #   loses its bottom; only the bottom goes, so what is left reads as the
  #   wrong aspect ratio rather than as a crop. Clamping the spawn centre is
  #   the fix and a `player.spawn` height is not: the eye is wherever the
  #   player left it (standing on the floor while walking, or after a Ctrl
  #   descent while flying), and config can only place the first pose.
  # - layer-surface-filter: adds `windows.layer_exclude`, a regex over
  #   layer-shell namespaces that keeps matching surfaces out of the room
  #   entirely. Per-namespace and not a boolean because the two kinds of layer
  #   want opposite treatment: a bar is furniture bolted to a monitor edge the
  #   room does not have, while rofi and the quickshell panels are the only
  #   way to open a window from inside the view. ./plugins.lua sets the
  #   pattern; see that file.
  patches = [
    ./hypr3d-deactivate-outside-render-pass.patch
    ./hypr3d-bsp-back-polygon-order.patch
    ./hypr3d-spawn-offset-coincident.patch
    ./hypr3d-layer-surface-filter.patch
    ./hypr3d-spawn-above-floor.patch
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  # pkg_check_modules asks for pixman-1, libdrm, xkbcommon and hyprgraphics,
  # the sources include hyprland's own headers on top, and the link line names
  # GLESv2 and EGL bare. Every one of those is either hyprland's own .pc (its
  # `dev` output, which chooseDevOutputs picks off the derivation below) or
  # something hyprland already builds against — libglvnd included, which is
  # what carries both GL libraries — so taking its buildInputs wholesale is
  # what satisfies them, from the compositor's own nixpkgs pin rather than this
  # tree's.
  buildInputs = [ hyprland ] ++ hyprland.buildInputs;

  # The plugin's own headers are found relative to src/, but the hyprland ones
  # are not: CMakeLists demands a -DHYPRLAND_HEADERS pointing at a root with
  # include/hyprland/{src,protocols} under it, which is what hyprpm assembles
  # by hand in /var/cache/hyprpm/$USER/headersRoot. The `dev` output of the
  # compositor derivation already has precisely that layout, so it can be
  # handed over as-is — and handing over *this* compositor's headers is also
  # what keeps the PLUGIN_INIT commit-hash check happy at load time.
  cmakeFlags = [ (lib.cmakeFeature "HYPRLAND_HEADERS" "${hyprland.dev}") ];

  # No install rules upstream (the hyprpm.toml just points at build/hypr3d.so),
  # and the target sets PREFIX "" so the file is not lib-prefixed in the build
  # tree. The lib<name>.so naming below is nixpkgs' convention for hyprland
  # plugins and is what ./home.nix links into ~/.config/hypr/plugins.
  installPhase = ''
    runHook preInstall

    install -Dm444 hypr3d.so $out/lib/libhypr3d.so

    runHook postInstall
  '';

  meta = {
    description = "Walkable 3D workspace for Hyprland";
    homepage = "https://github.com/samine825/Hypr3D";
    # MIT upstream; the vendored third_party/Jolt is MIT too.
    license = lib.licenses.mit;
    platforms = hyprland.meta.platforms;
  };
}
