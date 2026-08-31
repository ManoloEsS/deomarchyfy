-- Native Hyprland Lua entrypoint.
-- Unspecified settings remain at Hyprland's built-in defaults.

local home = os.getenv("HOME") or ""
local config_home = os.getenv("XDG_CONFIG_HOME")
if config_home == nil or config_home == "" then
  config_home = home .. "/.config"
end

-- Make modules under ~/.config/hypr available as hypr.*.
package.path = config_home .. "/?.lua;" .. package.path

require("hypr.monitors")
require("hypr.looknfeel")
require("hypr.bindings")

hl.on("hyprland.start", function()
  hl.exec_cmd("noctalia")
end)
