-- Hyprland config, hand-edited. ./home.nix wires this up: normally it is copied
-- into the store and symlinked to ~/.config/hypr/hyprland.lua, and with
-- `desktop.hyprland.mutableConfig` set that symlink points straight back here so
-- saves apply on the next `hyprctl reload` with no rebuild.
--
-- The lua API stubs live in the hyprland package under share/hypr/stubs. The
-- ./.luarc.json next to this file points lua-ls at them for editing in-tree,
-- and home-manager writes its own hypr/.luarc.json next to the deployed config.
-- An annotated example config sits with the stubs in share/hypr/hyprland.lua.

-- Two side-effect modules, in the order they are meant to apply:
--
--   ./binds.lua   every key binding that does not need a plugin, plus the
--                 $TERMINAL env that goes with the terminal bind
--   ./plugins.lua both hl.plugin.load() calls and everything that depends on
--                 one: the gloview binds and gestures, and the two plugin
--                 config blocks
--
-- plugins.lua requires binds.lua itself for the modifier; the require here is
-- still explicit, because the binds have to apply whether or not the plugins
-- do. Nothing is returned to this file; what is left below is the config that
-- belongs to hyprland proper.
--
-- `require` resolves module names against the deployed config's own directory
-- and nowhere else, so both files have to be installed next to hyprland.lua in
-- ~/.config/hypr; see the header in ./binds.lua and the xdg.configFile entries
-- in ./home.nix.
local terminal = require("binds").terminal
require("plugins")

hl.config({
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },
})

-- Startup Apps
--
-- `noctalia-session` rather than `noctalia`: it waits for hypridle to claim
-- org.freedesktop.ScreenSaver before starting the bar, which is what makes
-- firefox's "Playing video" idle inhibit reach the daemon that owns the dpms
-- timers. See `noctaliaSession` in ./home.nix for why the order is this way
-- round.
hl.on("hyprland.start", function()
  hl.exec_cmd("noctalia-session")
  hl.exec_cmd("[workspace 1] firefox")
  hl.exec_cmd("[workspace 2 silent] " .. terminal .. " -e tmux")
end)


hl.window_rule({
  match = { class = ".*" },
  idle_inhibit = "fullscreen",
})
-- hl.window_rule({
--   match = { title = "^(YouTube)$" },
--   idle_inhibit = "focus",
-- })



-- Noctalia Settings
hl.window_rule({
  match = { class = "dev.noctalia.Noctalia" },
  float = true,
  size = { 1080, 920 },
})

-- imv, the image viewer (./home.nix): floating (centred, as a new floating
-- window is), at three quarters of the monitor's 1440x960.
hl.window_rule({
  match = { class = "^imv$" },
  float = true,
  size = { 1080, 720 },
})

-- psxplay (~/src/ChrisRx/psxsdk/tools/psxplay), run directly or as
-- `go tool psxplay`. It never sets an X11 class, so it gets ebiten's default
-- Ebitengine-Application, which would match every ebiten program. Its title is
-- "psxplay", plus " - <file>" when given a disc or exe, and is set before the
-- window maps.
hl.window_rule({
  match = { initial_title = "^psxplay( - .*)?$" },
  float = true,
})

hl.window_rule({
  match = { initial_title = "^yaroze( - .*)?$" },
  float = true,
  -- Top right corner, 10px in from the right edge and 10px below the bar.
  -- move is relative to the monitor origin and ignores the reserved area, so
  -- the 40 is the noctalia bar's height (`hyprctl monitors` -> reserved).
  move = "monitor_w-window_w-10 50",
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
  debug = {
    damage_tracking = 0,
  },
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
      scroll_factor = 0.8,
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
