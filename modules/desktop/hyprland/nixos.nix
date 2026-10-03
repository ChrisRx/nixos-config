{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.desktop.hyprland;

  hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};

  # Upstream's flake ships share/wayland-sessions/hyprland-uwsm.desktop with a
  # bare `Exec=uwsm`, and gdm-session-worker replaces the session PATH with its
  # compiled-in default — gdm's own bin plus /usr/local/bin:/usr/bin:/bin:… —
  # which on NixOS holds no uwsm. execvp then fails with ENOENT before uwsm can
  # log a line, so the session dies in ~250ms and gdm reports only
  # "Session never registered, failing"; no hyprland log is written at all.
  #
  # nixpkgs' own hyprland substitutes an absolute path for exactly this reason,
  # which is why the nixpkgs 0.55.4 session worked and the flake's 0.56.0 one
  # does not. These are those same two replacements, applied in a symlink farm
  # rather than via overrideAttrs: changing the derivation would change its
  # hash and cost a local compile of the compositor on every pin move, which is
  # what the cachix substituter in ../../../flake.nix exists to avoid.
  #
  # The inherited attrs are what keep programs.hyprland working: it reads
  # version off cfg.package for its systemd.setPath default,
  # passthru.providedSessions for the sessionPackages assertion, and
  # meta.mainProgram via lib.getExe for security.wrappers.Hyprland below.
  #
  # --replace-fail is load-bearing. If upstream fixes this, renames the entry or
  # moves share/wayland-sessions, the rebuild fails here naming the offending
  # line rather than silently regressing to a blank login screen.
  #
  # enableXWayland is read back off programs.hyprland rather than hardcoded, so
  # it tracks xwayland.enable below; see the override note in `passthru` for why
  # it has to be applied here and not left to the module. Reading the option
  # while defining programs.hyprland.package is safe: xwayland does not itself
  # depend on the package.
  hyprlandBase = hyprland.hyprland.override {
    enableXWayland = config.programs.hyprland.xwayland.enable;
  };

  hyprlandPkg = pkgs.symlinkJoin {
    name = "hyprland-${hyprlandBase.version}-uwsm-session-path";

    # hyprland is multi-output (out, man, dev) and its meta.outputsToInstall
    # names "man", so both of the installed outputs have to be folded into the
    # single-output farm — otherwise environment.systemPackages asks it for a
    # `man` output it does not have, and the man pages would go missing anyway.
    paths = map (o: hyprlandBase.${o}) hyprlandBase.meta.outputsToInstall;
    inherit (hyprlandBase) version;
    meta = hyprlandBase.meta // {
      outputsToInstall = [ "out" ];
    };

    passthru = (hyprlandBase.passthru or { }) // {
      # `programs.hyprland.package` has an apply that runs the whole value
      # through genFinalPackage (nixos/modules/programs/wayland/lib.nix), which
      # reads lib.functionArgs off this attr to work out what it may pass, and
      # errors outright if the attr is missing. A symlink farm has no override
      # of its own, so enableXWayland is applied to hyprlandBase above and this
      # advertises no arguments, which makes genFinalPackage find nothing to
      # pass and hand the farm back untouched. Forwarding hyprlandBase.override
      # instead would let it override straight past the farm and lose the
      # session fix.
      override = _: hyprlandPkg;
    };

    postBuild = ''
      entry=$out/share/wayland-sessions/hyprland-uwsm.desktop
      rm "$entry"
      substitute ${hyprlandBase}/share/wayland-sessions/hyprland-uwsm.desktop "$entry" \
        --replace-fail "Exec=uwsm " "Exec=${lib.getExe pkgs.uwsm} " \
        --replace-fail "TryExec=uwsm" "TryExec=${lib.getExe pkgs.uwsm}"
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      # Use the flake inputs hyprland package so that plugins build and load
      # correctly. The symlink farm above only shadows the uwsm session entry;
      # the compositor binary it points at is the flake build byte for byte, so
      # the commit hash PLUGIN_INIT compares is unchanged.
      package = hyprlandPkg;
      # The portal is pinned alongside it deliberately: it is versioned in
      # lockstep with the compositor upstream, and leaving it on nixpkgs' build
      # pairs a 0.55.4 portal with a 0.56.0 session.
      portalPackage = hyprland.xdg-desktop-portal-hyprland;
    };
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.hyprland.enableGnomeKeyring = true;
    # TODO: Figure out why this isn't working. It is still asking to unlock the
    # keyring after login.
    security.pam.services.gdm.enableGnomeKeyring = true; # load gnome-keyring at startup
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
