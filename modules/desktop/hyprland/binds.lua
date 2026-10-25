-- Key bindings, split out of ./hyprland.lua. Everything here is plain
-- dispatchers and exec_cmd: nothing in this file depends on a plugin being
-- loaded. The two gloview binds live in ./plugins.lua instead, because
-- hl.plugin.gloview.* are real functions installed into that table by
-- hl.plugin.load(), so they only exist after the load call runs.
--
-- Loaded by `require("binds")` from ./hyprland.lua. Hyprland sets package.path
-- to the main config's own directory and nothing else
-- (`<configdir>/?.lua;<configdir>/?/init.lua`, see Lua::CConfigManager's ctor),
-- so this file has to be deployed next to hyprland.lua in ~/.config/hypr —
-- ./home.nix does that, giving it the same sealed-or-symlinked treatment as the
-- main config. The compositor also clears package.loaded for everything outside
-- the lua stdlib before re-running the config, so an edit here is picked up by
-- the next `hyprctl reload` rather than needing a restart.
--
-- A runtime error in here does not abort the rest of the config: hyprland wraps
-- `require` so the error lands in `hyprctl configerrors` and the require returns
-- an empty table.

-- The modifier everything below is bound on, returned for ./plugins.lua to
-- reuse for the two gloview binds. Defined here because this is where all but
-- those two of its uses are.
local mod = "SUPER"

local ipc = "noctalia msg "

-- Core binds
hl.bind(mod .. "+Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mod .. "+S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mod .. "+comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher"))

-- ghostty is the session terminal. $TERMINAL is the first thing noctalia's
-- launcher checks before falling back to its own candidate list, and it is what
-- most other "open a terminal" paths look at too. It lives next to the bind so
-- the two cannot drift apart.
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

return {
  mod = mod,
  terminal = terminal,
}
