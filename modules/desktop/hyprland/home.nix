# home-manager half of hyprland
{
  config,
  lib,
  pkgs,
  unstable,
  # This repo's flake inputs, set by homeModules.hyprland in ../../../flake.nix.
  # Not the usual `inputs`: a consumer flake that passes its own `inputs`
  # through extraSpecialArgs would shadow a `_module.args.inputs`, and its
  # inputs have no gloview or Hypr3D.
  flakeInputs,
  ...
}:

let
  cfg = config.desktop.hyprland;

  # The same derivation ./nixos.nix installs as the compositor. `pkgs.hyprland`
  # is the stable channel's 0.55.4 and is deliberately not used anywhere in
  # this file: a hyprctl from one build talking to a session from another is
  # the kind of skew that only shows up at runtime.
  hyprlandPkg = unstable.hyprland;

  # A lua config file, parsed before it ships. Without this a typo builds and
  # switches happily and only shows up when hyprland next reads the file, i.e.
  # at login. `pkgs.lua5_5` is not an approximation of hyprland's parser: it is
  # the same lua release the compositor links (5.5, checked against
  # `unstable.hyprland.buildInputs`), so it agrees with it on what parses. Only
  # the store path differs, since the compositor comes from nixpkgs-unstable.
  #
  # luac -p parses without executing, which matters because the file calls into
  # hl.* and would otherwise need the compositor to run. Anything past a syntax
  # error (unknown dispatchers, bad option names) still only surfaces at reload,
  # via `hyprctl configerrors`. `require` is in that second category too: each
  # file is parsed on its own, so a missing ./binds.lua is a reload-time error.
  checkedLua =
    name: path:
    let
      src = builtins.path { inherit name path; };
    in
    pkgs.runCommandLocal name { } ''
      ${pkgs.lua5_5}/bin/luac -p ${src}
      cp ${src} $out
    '';

  # One xdg.configFile entry for a file ./hyprland.lua pulls in with `require`.
  #
  # Hyprland resolves module names against the deployed config's own directory
  # and nowhere else, so each one has to land in ~/.config/hypr beside
  # hyprland.lua, and gets the same sealed-or-symlinked treatment. In mutable
  # mode the sibling is taken from the directory `mutableConfigPath` points at,
  # so a scratch hyprland.lua needs its modules beside it.
  luaModule = name: path: {
    source =
      if cfg.mutableConfig then
        config.lib.file.mkOutOfStoreSymlink "${dirOf cfg.mutableConfigPath}/${name}"
      else
        checkedLua name path;

    onChange = reloadHyprland;
  };

  # Reload every running instance, for a file home-manager did not generate
  # itself (it only wires its own up). Firing on a sealed-mode content change is
  # the useful half; in mutable mode the store path never changes, which is the
  # whole point. Shared by both lua files so editing either one reloads.
  reloadHyprland = ''
    (
      XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
      if [[ -d "/tmp/hypr" || -d "$XDG_RUNTIME_DIR/hypr" ]]; then
        for i in $(${hyprlandPkg}/bin/hyprctl instances -j | ${pkgs.jq}/bin/jq ".[].instance" -r); do
          ${hyprlandPkg}/bin/hyprctl -i "$i" reload config-only
        done
      fi
    )
  '';

  # `hyprctl dispatch` takes lua now. It wraps its argument in
  # `return hl.dispatch(<arg>)` and feeds that to the compositor's lua state, so
  # the hyprlang-era spelling no longer parses:
  #
  #   $ hyprctl dispatch dpms off
  #   error: [string "return hl.dispatch(dpms off)"]:1: ')' expected near 'off'
  #
  # The dispatcher has to be written as the lua call it has become. Single
  # quotes keep the inner double quotes intact through hypridle's `/bin/sh -c`.
  # `action` is one of "on", "off" or "toggle"; anything unrecognised silently
  # becomes "toggle", so it is worth getting right.
  dpms = action: "${hyprlandPkg}/bin/hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";

  # Hyprspace = flakeInputs.Hyprspace.packages.${pkgs.stdenv.hostPlatform.system}.Hyprspace;

  # All three plugins below are packaged in-tree from their input's source,
  # with `hyprlandPkg` handed in explicitly so each is compiled against the
  # same build the session runs.
  #
  # Packaged in-tree rather than taken from a flake output, because upstream
  # publishes neither. See ./hypr-kinetic-scroll.nix.
  hypr-kinetic-scroll = pkgs.callPackage ./hypr-kinetic-scroll.nix {
    hyprland = hyprlandPkg;
    src = flakeInputs.hypr-kinetic-scroll;
  };

  # Same arrangement, same reason. See ./hypr3d.nix.
  hypr3d = pkgs.callPackage ./hypr3d.nix {
    hyprland = hyprlandPkg;
    src = flakeInputs.Hypr3D;
  };

  # Same arrangement, different reason: gloview does ship a flake, and
  # `inputs.gloview.packages.*.gloview` is what this used to be. That output
  # builds the plugin against its own overrideAttrs'd compositor rather than
  # the one the session runs. ./gloview.nix has the detail. The input is
  # source only (`flake = false` in ../../../flake.nix), so its own lock never
  # drags a second Hyprland in.
  gloview = pkgs.callPackage ./gloview.nix {
    hyprland = hyprlandPkg;
    src = flakeInputs.gloview;
  };

  # The 360-degree backdrop for hypr3d's room, wired up in ./plugins.lua under
  # `world.panorama`. 2048x1024 of starfield with a crescent-lit ice planet.
  #
  # fetchurl rather than a flake input, which is the opposite of the three
  # plugins above. Those are *sources* that get compiled and have to move with
  # `nix flake update`; this is one immutable 137K asset that never wants
  # updating, and pinning it as an input would put the whole of three.js in
  # flake.lock to get at a single file.
  #
  # The format is not a free choice. hypr3d loads this through
  # Hyprgraphics::CImage into a cairo surface, and hyprgraphics links only
  # libjpeg, libpng, libwebp and libjxl — there is no Radiance HDR, EXR or TIFF
  # codec anywhere in it, so the .hdr files that panoramas are normally
  # distributed as (Poly Haven's whole library, NASA's star maps) load as
  # nothing and leave the default void behind. LDR, and exactly 2:1: the shader
  # maps longitude across the full width and latitude pole to pole over the
  # full height, so any other aspect ratio is stretched rather than cropped.
  #
  # Space suits the room better than the usual landscape HDRI for a reason
  # worth keeping: equirectangular projection smears the poles, and a landscape
  # capture puts a visibly stretched blob directly overhead and underfoot,
  # exactly where you look when flying. A starfield is near-uniform there and
  # hides it. It is also dark enough that window quads keep their contrast.
  #
  # Provenance is the one loose end. It arrived in three.js via PR #29715 (the
  # LensflareNode addon, Oct 2024) with no credit file and no metadata beyond a
  # Google ICC profile, so unlike the Poly Haven material in the same directory
  # it carries no stated licence. Fine as the personal backdrop it is; resolve
  # it before this image ends up anywhere public.
  hypr3dPanorama = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/mrdoob/three.js/r180/examples/textures/equirectangular/ice_planet_close.jpg";
    hash = "sha256-cTHYaqzh3g1I75UrNWXMAVgaeFQ82pXyqyNFworjUAY=";
  };

  # Where ../wallpapers ends up in $HOME. Every noctalia wallpaper path has to
  # be absolute by the time it reaches config.toml; see the home.file entry
  # below for why it is this and not a store path.
  wallpaperDir = "${config.home.homeDirectory}/.config/wallpapers";

  # True only when this machine has a mains supply *and* it is unplugged.
  #
  # The "and" matters: a desktop has no Mains power_supply device at all, and
  # answering "on battery" there would idle-suspend a machine that has no
  # battery to save. So a missing supply reports plugged in, and the two
  # battery-gated listeners below simply never fire.
  #
  # Scanning for type == Mains rather than hardcoding a name avoids baking in
  # fw13's ACAD, which is just what its ACPI tables call the adapter; elsewhere
  # the same device is AC, AC0, ADP0 or ADP1. The ucsi-source-psy-* devices next
  # to it are USB-PD port state and report type USB, so they are skipped.
  onBattery = pkgs.writeShellScript "on-battery" ''
    found=0
    for ps in /sys/class/power_supply/*; do
      [ "$(cat "$ps/type" 2>/dev/null)" = Mains ] || continue
      found=1
      [ "$(cat "$ps/online" 2>/dev/null)" = 1 ] && exit 1
    done
    [ "$found" = 1 ]
  '';

  # noctalia and hypridle both try to own org.freedesktop.ScreenSaver, and the
  # bus gives it to whoever asks first and never reassigns it. That name decides
  # whether video playback keeps the display on: firefox probes wake-lock
  # backends in order and takes the FreeDesktopScreensaver one long before it
  # would reach wayland's idle-inhibit protocol, so the holder of the name is
  # the only process that ever hears "Playing video".
  #
  # uwsm activates graphical-session.target, and with it hypridle.service, only
  # once the compositor's own service is up — and the compositor is what spawns
  # noctalia. So noctalia asked first every session, by about a second:
  #
  #   10:47:11  wayland-wm@hyprland.desktop.service active -> noctalia starts
  #   10:47:12  graphical-session.target active -> hypridle.service starts
  #             hypridle: [ERR] Another service is already providing the
  #                       org.freedesktop.ScreenSaver interface
  #
  # firefox's inhibit then landed on noctalia, which applies it only to its own
  # idle behaviours — unconfigured here, there is no [idle] in `settings` below
  # — while hypridle never saw an inhibit lock and blanked the display mid-video
  # on the 300s listener. Holding noctalia back until the name is taken inverts
  # that pair. Ordering alone would not do it: hypridle is Type=simple with no
  # BusName, so systemd calls it started before it has claimed anything.
  #
  # Losing the race is a case noctalia already handles. Its ScreenSaverService
  # treats an existing owner as a FileExists error, drops the service and
  # continues, so the caffeine toggle and its logind idle monitor still work;
  # only the screensaver-inhibit feed it was not using is given up.
  #
  # Fail-open after 5s, because a hypridle that never claims the name costs the
  # ordering guarantee, and that is worth less than a session with no bar.
  noctaliaSession = pkgs.writeShellScriptBin "noctalia-session" ''
    screensaver_taken() {
      ${pkgs.systemd}/bin/busctl --user call org.freedesktop.DBus \
        /org/freedesktop/DBus org.freedesktop.DBus NameHasOwner \
        s org.freedesktop.ScreenSaver 2>/dev/null |
        ${pkgs.gnugrep}/bin/grep -q true
    }

    waited=0
    until screensaver_taken || [ "$waited" -ge 50 ]; do
      ${pkgs.coreutils}/bin/sleep 0.1
      waited=$((waited + 1))
    done

    exec ${lib.getExe config.programs.noctalia.package} "$@"
  '';
in
{
  # noctalia's home module is imported by homeModules.hyprland in
  # ../../../flake.nix rather than here: `flakeInputs` is a `_module.args`
  # value, and those cannot be used in `imports` without infinite recursion.

  config = lib.mkIf cfg.enable {
    # ./hyprland.lua starts the session's bar through this rather than calling
    # `noctalia` directly, so the wrapper has to be on PATH for it to find.
    home.packages = [ noctaliaSession ];

    # uwsm sources this for every compositor it starts, before the session's
    # units come up, so it reaches everything launched inside the session.
    # Doubles ./nixos.nix's environment.sessionVariables on NixOS; standalone
    # home-manager has nothing else to set it.
    xdg.configFile."uwsm/env".text = ''
      export NIXOS_OZONE_WL=1
    '';

    wayland.windowManager.hyprland = {
      enable = true;

      # Lua rather than hyprlang: `configType` only defaults to "lua" from
      # home.stateVersion 26.05 onwards and ../../nixos/core/user.nix is still
      # on 25.11, so getting ~/.config/hypr/hyprland.lua takes an explicit set.
      configType = "lua";

      # The compositor, its session entry and the portal are all installed by
      # the NixOS half (./nixos.nix), so nothing here needs to install them
      # again — but `package` is deliberately not null, for two reasons.
      #
      # It is what gets hypr/.luarc.json written, which points lua-ls at the hl
      # API stubs under share/hypr/stubs while editing ./hyprland.lua. And it
      # has to name the *same* build ./nixos.nix installs, or those stubs
      # describe a different compositor than the one that reads the config.
      # Leaving it at its default would silently pick the stable channel's
      # 0.55.4.
      package = hyprlandPkg;
      portalPackage = null;

      # uwsm owns the session (withUWSM in ./nixos.nix).
      systemd.enable = false;

      # `settings` and `extraConfig` are deliberately unused: ./hyprland.lua is
      # the whole config, so there is no generated half to diverge from while
      # the escape hatch below is on. Anything that genuinely needs a nix value
      # interpolated into it can still be added here, but it would then only
      # apply in the sealed mode, since `source` replaces the generated file.

      # `plugins` is deliberately left empty. It renders into the *generated*
      # hyprland.lua as
      #
      #   hl.on("hyprland.start", function()
      #     hl.exec_cmd("hyprctl plugin load /nix/store/…/libhyprtasking.so")
      #   end)
      #
      # and home-manager turns that generated text into `source` with
      # mkDefault, which the plain `source` below replaces wholesale. Anything
      # put here is silently dropped. ./hyprland.lua calls hl.plugin.load()
      # itself instead, against the stable path set up further down.
    };

    # hl.plugin.load() needs an absolute path, and ./hyprland.lua is hand-edited
    # (and in mutable mode not even in the store), so it cannot have one
    # interpolated into it. Pointing the lua at a fixed
    # ~/.config/hypr/plugins/ entry moves the store path back onto the nix
    # side, where a plugin rebuild just repoints the symlink.
    #
    # Each link is gated on its `desktop.hyprland.plugins.<name>.enable`, and
    # nothing else references the derivation, so a disabled plugin is never
    # built at all.
    xdg.configFile."hypr/plugins/libgloview.so" = lib.mkIf cfg.plugins.gloview.enable {
      source = "${gloview}/lib/libgloview.so";
    };
    xdg.configFile."hypr/plugins/libhypr-kinetic-scroll.so" =
      lib.mkIf cfg.plugins.kineticScroll.enable
        {
          source = "${hypr-kinetic-scroll}/lib/libhypr-kinetic-scroll.so";
        };
    xdg.configFile."hypr/plugins/libhypr3d.so" = lib.mkIf cfg.plugins.hypr3d.enable {
      source = "${hypr3d}/lib/libhypr3d.so";
    };

    # The same flags, handed to ./plugins.lua, which skips each disabled
    # plugin's whole section. Always generated, never symlinked live: it has to
    # agree with the .so links above, and those only change on a switch.
    xdg.configFile."hypr/enabled_plugins.lua" = {
      text = "return " + lib.generators.toLua { } (lib.mapAttrs (_: p: p.enable) cfg.plugins) + "\n";
      onChange = reloadHyprland;
    };

    # `world.panorama` is the same problem as the three .so paths above and gets
    # the same answer: ./plugins.lua names it, ./plugins.lua has no nix
    # interpolation, so the store path is held here and the lua points at a
    # fixed name in $HOME. Not under plugins/ because that directory is what
    # hl.plugin.load() reads and only .so files belong in it, and not in
    # ~/.config/wallpapers either — that one is noctalia's picker directory, and
    # an equirectangular image is badly distorted shown flat as a desktop
    # background.
    #
    # The plugin stats this path every frame and reloads the texture when the
    # mtime changes, so a different image is live on the next switch without a
    # reload. A path that does not exist is not silently ignored: it raises an
    # on-screen "[hypr3d] panorama file not found" notification, once per path.
    xdg.configFile."hypr/panorama.jpg" = lib.mkIf cfg.plugins.hypr3d.enable {
      source = hypr3dPanorama;
    };

    # ../wallpapers, linked into $HOME rather than interpolated into
    # programs.noctalia.settings as a store path.
    #
    # Noctalia resolves wallpaper paths at runtime, not at build time: a
    # relative path in config.toml goes through std::filesystem::absolute(),
    # which prepends the shell's own CWD ($HOME under uwsm), so "../wallpapers"
    # would look for /home/wallpapers. Absolute is the only spelling that works,
    # and "${../wallpapers}" would satisfy that — but it points the picker at a
    # read-only store directory, so adding or removing an image means a rebuild.
    # (Favourites and the last-selected wallpaper are unaffected either way:
    # those live in $XDG_STATE_HOME/noctalia, not in the config.toml below.)
    #
    # `recursive` is what makes this mutable: without it home-manager symlinks
    # the directory itself and ~/.config/wallpapers *is* the store path again.
    # With it, each image is linked individually into a real directory, so
    # anything dropped in alongside them is picked up with no rebuild. The
    # linked images stay read-only, and are restored on the next switch if
    # removed by hand.
    home.file.".config/wallpapers" = {
      source = ../wallpapers;
      recursive = true;
    };

    gtk = {
      gtk4 = {
        enable = true;
        # TODO: Doesn't work
        # theme = {
        #   package = pkgs.catppuccin-gtk-theme;
        #   name = "";
        # };
        iconTheme = {
          package = pkgs.adwaita-icon-theme;
          name = "Adwaita";
        };
        cursorTheme = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
        };
        extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };
    };

    # Cursor. Nothing set one before, so the session ran on whatever the
    # fallback index.theme resolved to (Adwaita was the only theme installed).
    #
    # The bare submodule is deliberately all that is set here: on its own it
    # already installs the package, sets XCURSOR_THEME/XCURSOR_SIZE, extends
    # XCURSOR_PATH and writes the icons/default/index.theme links, which is the
    # whole story for hyprland, xwayland and the qt/gtk toolkits.
    #
    #   - gtk.enable is left off on purpose: home-manager only *generates* the
    #     gtk cursor config there, and applying it needs `gtk.enable`, which
    #     this config does not set. Turning it on would write a file nothing
    #     reads.
    #   - hyprcursor.enable is left off because bibata-cursors ships only
    #     XCursor themes under share/icons; there is no hyprcursor build in the
    #     package, and hyprland falls back to XCursor cleanly.
    home.pointerCursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      # The submodule defaults to 32, which is oversized on a 2880x1920 panel
      # already running at scale 2.
      size = 24;
    };

    # ./hyprland.lua and the modules it requires are hand-edited either way; the
    # flag only decides whether they reach ~/.config/hypr as store copies or as
    # symlinks pointing back at the working tree:
    #
    #   off: ~/.config/hypr/hyprland.lua -> /nix/store/…-hyprland.lua (a copy)
    #   on:  ~/.config/hypr/hyprland.lua -> /nix/store/…-hyprland.lua -> here
    #
    # With it on, a save is picked up by the next `hyprctl reload` with no
    # rebuild and no activation; with it off the same bytes are sealed into the
    # store, so switching back needs no translation, just a rebuild.
    #
    # home-manager derives `source` from its own generated `text` with
    # mkDefault, so this plain definition wins without a mkForce.
    xdg.configFile."hypr/hyprland.lua" = {
      # The live path is deliberately unchecked: it is whatever is on disk at
      # reload time, which is the point of the flag, and nothing about it is
      # known at build time.
      source =
        if cfg.mutableConfig then
          config.lib.file.mkOutOfStoreSymlink cfg.mutableConfigPath
        else
          checkedLua "hyprland.lua" ./hyprland.lua;

      onChange = reloadHyprland;
    };

    # The directory next to these, hypr/plugins/, holds the .so files and is
    # unrelated to hypr/plugins.lua despite the name.
    xdg.configFile."hypr/binds.lua" = luaModule "binds.lua" ./binds.lua;
    xdg.configFile."hypr/plugins.lua" = luaModule "plugins.lua" ./plugins.lua;

    # Idle handling. hypridle has no lua config of its own: it is still hyprlang
    # in ~/.config/hypr/hypridle.conf, generated from this attrset. Only the
    # commands it runs had to move to lua, see `dpms` above.
    #
    # The daemon is started by its own systemd user unit, bound to
    # graphical-session.target, which uwsm brings up. ../hyprland.lua used to
    # `exec_cmd("hypridle")` instead; both at once would have the second
    # instance fail to claim the org.freedesktop.ScreenSaver name.
    #
    # Policy, by power source:
    #
    #   on battery: display off at 5min, suspend-then-hibernate at 30min
    #   on AC:      display off at 15min, never sleeps
    #
    # Each listener fires once per idle period, so the power source is sampled
    # at the moment its timeout elapses and not again. Unplugging *while*
    # already idle past 30min therefore does not retroactively suspend; the
    # machine sleeps on the next idle period instead. hypridle 0.1.8 adds
    # per-listener `condition_cmd` + `condition_retry` which re-checks on an
    # interval and would close that gap, but nixpkgs is still on 0.1.7.
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          # logind's Lock signal, which `loginctl lock-session` raises, is what
          # gets a locker on screen; hypridle answers it by running this.
          lock_cmd = "noctalia msg session lock";

          # hypridle holds a delay inhibitor on sleep, so this runs and the
          # lockscreen comes up before the machine actually goes down. Without
          # it a resume from the 30min suspend below lands on a live desktop.
          before_sleep_cmd = "/run/current-system/sw/bin/loginctl lock-session";

          # Resume leaves the outputs off otherwise, and the keypress that
          # wakes them is then swallowed rather than reaching the lockscreen.
          after_sleep_cmd = dpms "on";
        };

        listener = [
          # Display, on battery. `on-resume` is deliberately left unguarded:
          # turning outputs back on when they were never turned off is a no-op,
          # and gating it would strand the display off across a plug-in.
          {
            timeout = 300;
            on-timeout = "${onBattery} && ${dpms "off"}";
            on-resume = dpms "on";
          }

          # Display, on AC. Ungated on purpose: on battery the 5min listener has
          # already blanked the outputs by now and a second dpms off changes
          # nothing, which is cheaper than a second power-source check.
          {
            timeout = 900;
            on-timeout = dpms "off";
            on-resume = dpms "on";
          }

          # Sleep, battery only. suspend-then-hibernate rather than plain
          # suspend to match HandleLidSwitch in ../../../hosts/fw13; the
          # handover is governed by HibernateDelaySec in the same file.
          {
            timeout = 1800;
            on-timeout = "${onBattery} && /run/current-system/sw/bin/systemctl suspend-then-hibernate";
          }
        ];
      };
    };

    programs.noctalia = {
      enable = true;

      # `settings` merges per key, so a host can add to this tree directly:
      #
      #   home-manager.users.chris.programs.noctalia.settings.dock.show_dots = false;
      #
      # A key already defined below needs `lib.mkForce` on the host side.
      settings = {
        config_version = 12;

        audio.enable_sounds = false;

        bar.default = {
          # Draw every widget in its own capsule unless a group below claims it.
          capsule = true;
          color = "primary";
          concave_edge_corners = false;
          font_family = "FiraCode Nerd Font";
          icon_color = "primary";
          margin_ends = 0;
          padding = 10;
          radius = 0;
          thickness = 40;
          widget_spacing = 10;
          start = [
            "workspaces"
            "group:g1"
            "wallpaper"
            "toggle"
          ];
          end = [
            "tray"
            "bluetooth"
            "network"
            "volume"
            "brightness"
            "battery"
            "session"
          ];

          capsule_group = [
            {
              id = "g1";
              members = [
                "cpu"
                "GPU"
                "ram"
              ];
              accordion = false;
              accordion_direction = "end";
              enabled = true;
              fill = "surface_variant";
              opacity = 1.0;
              padding = 6.0;
            }
          ];
        };
        dock.show_dots = true;

        location.auto_locate = true;

        lockscreen = {
          blur_intensity = 0.0;
          # wallpaper = "${wallpaperDir}/bg.jpg";
        };

        shell = {
          app_icon_color = "error";
          polkit_agent = true;
          launcher.categories = false;
        };

        theme = {
          mode = "dark";
          source = "wallpaper";
          wallpaper_scheme = "faithful";
          # source = "builtin";
          # builtin = "Catppuccin";
        };

        wallpaper = {
          enabled = true;
          directory = wallpaperDir;
          fill_mode = "crop";
          default.path = "${wallpaperDir}/bg.jpg";
        };

        plugins = {
          enabled = [ "maddingo/hypr-layout-switcher" ];
          auto_update = "none";
        };

        # Per-widget settings, keyed by the widget id used in the lanes above. An
        # id with no `type` *is* its type, which is why cpu and ram need nothing
        # but a stat; GPU is a second sysmon instance under its own id, so it has
        # to name the type it instantiates.
        widget.GPU = {
          type = "sysmon";
          stat = "gpu_usage";
        };

        widget.ram.stat = "ram_pct";

        widget.toggle.type = "maddingo/hypr-layout-switcher:toggle";

        # Left in bar.default.end rather than removed from the lane, so the
        # widget is one `enabled` flip away from coming back.
        widget.network.enabled = false;

        widget.clock.format = "{:%A %-e %B %Y %-I:%M %P}";

        widget.bluetooth = {
          hide_when_adapter_off = true;
          hide_when_no_connected_device = true;
        };
      };
    };
  };
}
