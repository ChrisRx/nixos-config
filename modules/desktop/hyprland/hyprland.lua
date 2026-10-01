-- Hyprland config, hand-edited. ./home.nix wires this up: normally it is copied
-- into the store and symlinked to ~/.config/hypr/hyprland.lua, and with
-- `desktop.hyprland.mutableConfig` set that symlink points straight back here so
-- saves apply on the next `hyprctl reload` with no rebuild.
--
-- The lua API stubs live in the hyprland package under share/hypr/stubs. The
-- ./.luarc.json next to this file points lua-ls at them for editing in-tree,
-- and home-manager writes its own hypr/.luarc.json next to the deployed config.
-- An annotated example config sits with the stubs in share/hypr/hyprland.lua.

local mod = "SUPER"
local ipc = "noctalia msg "

-- Startup Apps
hl.on("hyprland.start", function()
  hl.exec_cmd("noctalia")
end)

-- Noctalia Settings
hl.window_rule({
  match = { class = "dev.noctalia.Noctalia" },
  float = true,
  size = { 1080, 920 },
})
hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
  },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = false,
  blur_popups = false,
})

-- Core binds
hl.bind(mod .. "+Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mod .. "+S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mod .. "+comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher"))

hl.config({
  general = {
    border_size = 0,
    gaps_in = 3,
    gaps_out = 0,
    col = {
      active_border = "#a1f1b1",
      inactive_border = "#444444"
    },
    resize_on_border = true,
    extend_border_grab_area = 15,
  },
  -- debug = {
  --   damage_tracking = 0,
  -- },
  decoration = {
    -- screen_shader = "/etc/nixos/nixos-config/modules/desktop/hyprland/shaders/obra_dinn.glsl",
    -- screen_shader = "/etc/nixos/nixos-config/modules/desktop/hyprland/shaders/vhs.frag",
    blur = {
      enabled = false
    },
    shadow = {
      enabled = false
    },
  },
})

hl.plugin.load(os.getenv("HOME") .. "/.config/hypr/plugins/libgloview.so")

hl.bind(mod .. " + W", hl.plugin.gloview.toggle)
hl.bind(mod .. " + SHIFT + W", hl.plugin.gloview.allworkspaces)

-- Three fingers up opens the overview, down closes it.
--
-- `action` has to be the lua-function form: as a string it only accepts
-- hyprland's own built-ins (workspace, move, resize, close, float, fullscreen,
-- cursor_zoom, scroll_move, special, unset), so a dispatcher name like
-- "gloview:open" is rejected at reload with `unknown action`. Beware that the
-- string "close" is not the one you want either: it closes the *window*.
--
-- A one-function action is called once when the fingers lift, with no
-- arguments, which is what a discrete open/close wants. This has to sit after
-- the hl.plugin.load() above: hl.plugin.gloview.* are real functions installed
-- into the table at load time, not lazily resolved names.
--
-- Two separate up/down gestures rather than one "vertical": a vertical
-- registration cannot tell the two apart, and it would shadow any later up or
-- down at the same finger count. The direction is read off the raw swipe delta,
-- so input.touchpad.natural_scroll below does not invert it.
hl.gesture({ fingers = 3, direction = "up", action = hl.plugin.gloview.open })
hl.gesture({ fingers = 3, direction = "down", action = hl.plugin.gloview.close })

hl.config({
  plugin = {
    gloview = {
      layout                    = "rows",
      gap                       = 34,
      padding                   = 80,
      padding_top               = 40,
      padding_bottom            = 70,
      max_scale                 = 1.0,
      preview_filter            = "box4",
      duration                  = 200,
      preview_round             = 12,
      blur                      = 1,

      switch_animation          = 1,
      switch_duration           = 260,
      move_animation            = 1,
      move_duration             = 240,

      anchor                    = "top",
      strip_offset              = 0,
      strip_height              = 150,
      strip_margin              = 22,
      strip_gap                 = 18,
      strip_card_round          = 10,

      focus_follows_mouse       = 1,
      scroll_switches_workspace = 1,
      passthrough_keys          = 1,
      exit_on_click             = 1,
      exit_on_switch            = 0,

      key_close                 = "escape",
      key_next_workspace        = "tab",
      key_prev_workspace        = "shift+tab",
      key_activate              = "enter",
      key_close_window          = "d",
      key_left                  = "left",
      key_right                 = "right",
      key_up                    = "up",
      key_down                  = "down",
      key_desktop               = "shift",
      key_all_workspaces        = "a",
      key_workspace             = "1,2,3,4,5,6,7,8,9,0",

      show_all_workspaces       = 0,
      show_empty                = 1,
      dynamic_workspaces        = 1,
      autodelete_empty          = 1,
      show_workspace_labels     = 1,
      show_window_labels        = 1,
      show_special              = 0,
      strip_all_card            = 1,
      drag_to_swap              = 1,
      switch_on_drop            = 0,
      switch_on_new_workspace   = 1,

      hide_top_layers           = 0,
      hide_overlay_layers       = 0,
      above_namespaces          = "",
      debug_logs                = 0,

      select_border_size        = 3,
      select_border             = "#a1f1b1",
      close_button_color        = 0xe6e23b3b,
      backdrop_color            = "#070a10d0",
      strip_band_color          = "#00000000",
      strip_card_color          = 0x3a0e131c,
      strip_active_color        = 0x4d1c2c44,
      strip_active_border       = 0xf0ffffff,
      strip_hover_border        = 0x80ffffff,
      strip_active_border_size  = 2,
      strip_hover_border_size   = 2,
      strip_plus_color          = 0xd0eef4ff,
      preview_bg                = 0xff14181f,
      shadow_color              = 0x70000000,
      hover_border              = "#a1f1b1",
      hover_border_size         = 3,
    },
  },
})

-- Caps lock acts as another control. Hyprland does its own xkb setup rather than
-- reading the NixOS-level keymap, so this is the whole story for the session,
-- xwayland apps included. It does not reach the greeter or a TTY.
hl.config({
  input = {
    kb_options = "caps:ctrl_modifier",

    -- Natural scrolling: content follows the fingers, macOS-style. This is the
    -- touchpad knob only; input.natural_scroll covers mice and wheels and is
    -- left alone on purpose.
    touchpad = {
      natural_scroll = true,

      -- [1.0] two-finger scroll rate. Half speed; the default overshot every
      -- short flick.
      --
      -- Note apps that curve scrolling themselves (electron, anything with its
      -- own momentum) respond to this less than native gtk/qt ones do.
      scroll_factor = 1.0,
    },
  },
})

-- Swipe feel, tuned to land close to gnome's. Defaults are in brackets.
--
-- The position during a swipe is driven by the fingers, not by any animation,
-- so everything about how much travel a switch takes lives here; the animation
-- further down only plays once the fingers lift.
hl.config({
  gestures = {
    -- [300] px of travel for a full workspace transition. The single biggest
    -- lever on "how much gesture does this take".
    workspace_swipe_distance = 180,

    -- [0.5] fraction of that distance needed to commit rather than snap back.
    -- Together with the above: ~45px to commit, down from 150.
    workspace_swipe_cancel_ratio = 0.25,

    -- [30] speed that forces a switch regardless of distance, i.e. a flick.
    -- Raise toward 20-25 if a hard flick ever triggers unintentionally.
    workspace_swipe_min_speed_to_force = 15,

    -- [false] and deliberately left off. Turning it on lets one gesture run
    -- past the neighbouring workspace, which overshoots on a flick: a 1 -> 2
    -- swipe lands on 3. Gnome only traverses multiple workspaces on a
    -- sustained drag, never on a flick, so clamping matches it more closely.
    workspace_swipe_forever = false,
  },
})

-- Three fingers sideways moves between workspaces. Hyprland 0.51 moved the
-- *enable* switch out of `gestures.workspace_swipe` into this per-gesture form.
-- The `gestures.workspace_swipe_*` tuning below is NOT obsolete: those keys
-- still exist and still apply to this gesture. They just default to values
-- tuned for a longer, more deliberate swipe than gnome's.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace", })

-- Settle animation after the fingers lift. speed is in deciseconds, so 3 is
-- 300ms, near gnome's ~250ms; the previous 8 (800ms) read as floaty.
--
-- The curve is a plain ease-out cubic and deliberately does not pass 1.0: an
-- overshooting control point springs back at the end of the transition, which
-- reads as the workspace snapping rather than settling.
hl.curve("gnome_ease", { type = "bezier", points = { { 0.33, 1.0 }, { 0.68, 1.0 } } })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "gnome_ease" })

-- ghostty is the session terminal. $TERMINAL is the first thing noctalia's
-- launcher checks before falling back to its own candidate list, and it is what
-- most other "open a terminal" paths look at too.
local terminal = "ghostty"
hl.env("TERMINAL", terminal)

hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))

hl.bind(mod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "d" }))

hl.bind(mod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + j", hl.dsp.focus({ direction = "d" }))

hl.bind(mod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))

-- Execute Rofi with only the SUPER key
hl.bind(mod .. " + Super_L", hl.dsp.exec_cmd("pkill rofi || rofi -show drun"))

hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())

hl.bind(mod .. " + bracketleft", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mod .. " + bracketright", hl.dsp.focus({ workspace = "m+1" }))

hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))

for i = 1, 10 do
  local key = i % 10
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Media keys. These route through noctalia rather than wpctl/brightnessctl so
-- the shell draws its OSD for the change; going straight to wpctl moves the
-- volume silently, and brightnessctl is not installed at all. No step argument
-- is passed, which leaves the size to noctalia's own configured step.
--
-- `locked` keeps them live while the session is locked, and `repeating` lets
-- the level ramp when a key is held. Mute and mic-mute are toggles, so they
-- deliberately do not repeat.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true })

-- Transport controls, driven over MPRIS by the same shell. These are discrete
-- actions rather than levels, so none of them repeat: holding next would
-- otherwise run the playlist off the end.
--
-- Play and Pause are bound to the same toggle on purpose: which of the two a
-- keyboard emits for its single play/pause key varies, and binding both costs
-- nothing. There is no XF86AudioPlayPause keysym, despite the name appearing
-- in plenty of configs; XF86keysym.h defines only Play (0x1008ff14) and Pause
-- (0x1008ff31), and hyprland rejects the invented one at parse time.
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("noctalia msg media next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })


hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"))

-- mouse movements
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. "+ SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })
