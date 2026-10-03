# home-manager half of hyprland
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.desktop.hyprland;

  # The same derivation ./nixos.nix installs as the compositor. `pkgs.hyprland`
  # is nixpkgs' 0.55.4 and is deliberately not used anywhere in this file: a
  # hyprctl from one build talking to a session from another is the kind of
  # skew that only shows up at runtime.
  hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

  luaConfig = builtins.path {
    path = ./hyprland.lua;
    name = "hyprland.lua";
  };

  # ./hyprland.lua, parsed before it ships. Without this a typo builds and
  # switches happily and only shows up when hyprland next reads the file, i.e.
  # at login. `pkgs.lua5_5` is not an approximation of hyprland's parser: it is
  # the same lua release the compositor links (5.5, checked against the
  # `hyprland` input's buildInputs), so it agrees with it on what parses. Only
  # the store path differs now that the compositor comes from its own nixpkgs.
  #
  # luac -p parses without executing, which matters because the file calls into
  # hl.* and would otherwise need the compositor to run. Anything past a syntax
  # error (unknown dispatchers, bad option names) still only surfaces at reload,
  # via `hyprctl configerrors`.
  checkedLuaConfig = pkgs.runCommandLocal "hyprland.lua" { } ''
    ${pkgs.lua5_5}/bin/luac -p ${luaConfig}
    cp ${luaConfig} $out
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

  # Hyprspace = inputs.Hyprspace.packages.${pkgs.stdenv.hostPlatform.system}.Hyprspace;
  gloview = inputs.gloview.packages.${pkgs.stdenv.hostPlatform.system}.gloview;

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
in
{
  # Unconditional: `imports` cannot be wrapped in `lib.mkIf`. The module only
  # declares `programs.noctalia`, which stays disabled until the config below
  # turns it on.
  imports = [ inputs.noctalia.homeModules.default ];

  config = lib.mkIf cfg.enable {
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
      # Leaving it at its default would silently pick nixpkgs' 0.55.4.
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
    xdg.configFile."hypr/plugins/libgloview.so".source = "${gloview}/lib/libgloview.so";

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

    # ./hyprland.lua is hand-edited either way; the flag only decides whether it
    # reaches ~/.config/hypr/hyprland.lua as a store copy or as a symlink
    # pointing back at the working tree:
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
          checkedLuaConfig;

      # home-manager only reloads hyprland for files it generated itself, which
      # this is not. Firing on a sealed-mode content change is the useful half;
      # in mutable mode the store path never changes, which is the whole point.
      onChange = ''
        (
          XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
          if [[ -d "/tmp/hypr" || -d "$XDG_RUNTIME_DIR/hypr" ]]; then
            for i in $(${hyprlandPkg}/bin/hyprctl instances -j | ${pkgs.jq}/bin/jq ".[].instance" -r); do
              ${hyprlandPkg}/bin/hyprctl -i "$i" reload config-only
            done
          fi
        )
      '';
    };

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
