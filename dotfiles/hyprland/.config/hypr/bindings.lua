-- Personal native Hyprland bindings. No Omarchy helpers are required here.

local main_mod = "SUPER"

local function noctalia(message)
  return hl.dsp.exec_cmd("noctalia msg " .. message)
end

local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({
      mods = mods,
      key = key,
      state = "down",
      window = "activewindow",
    }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({
        mods = mods,
        key = key,
        state = "up",
        window = "activewindow",
      }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function master_only(layout_command)
  return function()
    local workspace = hl.get_active_workspace()
    if workspace and workspace.tiled_layout == "master" then
      hl.dispatch(hl.dsp.layout(layout_command))
    end
  end
end

local function scrolling_only(layout_command)
  return function()
    local workspace = hl.get_active_workspace()
    if workspace and workspace.tiled_layout == "scrolling" then
      hl.dispatch(hl.dsp.layout(layout_command))
    end
  end
end

local function toggle_scrolling_master()
  local workspace = hl.get_active_workspace()
  if not workspace then
    return
  end

  hl.config({
    general = {
      layout = workspace.tiled_layout == "scrolling" and "master" or "scrolling",
    },
  })
end

local single_window_square = false
local function toggle_single_window_aspect_ratio()
  single_window_square = not single_window_square
  hl.config({
    layout = {
      single_window_aspect_ratio = single_window_square and { 1, 1 } or { 0, 0 },
    },
  })
end

local function pop_window_out()
  local window = hl.get_active_window()
  if not window then
    return
  end

  if not window.floating then
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  end
  if not window.pinned then
    hl.dispatch(hl.dsp.window.pin())
  end
end

-- Core applications and universal clipboard shortcuts.
local terminal_home = os.getenv("HOME") or ""
local terminal_launcher = terminal_home .. "/.local/bin/deomarchyfy-launch-terminal"
hl.bind(main_mod .. " + RETURN", hl.dsp.exec_cmd(terminal_launcher))
hl.bind(main_mod .. " + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + C", send_shortcut_once({ "CTRL" }, "C"))
hl.bind(main_mod .. " + V", send_shortcut_once({ "CTRL" }, "V"))
hl.bind(main_mod .. " + X", send_shortcut_once({ "CTRL" }, "X"))
hl.bind(main_mod .. " + E", hl.dsp.exec_cmd("nautilus --new-window"))
hl.bind(main_mod .. " + SPACE", noctalia("panel-toggle launcher"))

-- Focus, swap, and workspace navigation.
local directions = {
  { key = "H", direction = "l" },
  { key = "J", direction = "d" },
  { key = "K", direction = "u" },
  { key = "L", direction = "r" },
}

for _, entry in ipairs(directions) do
  hl.bind(main_mod .. " + " .. entry.key, hl.dsp.focus({ direction = entry.direction }))
  hl.bind(main_mod .. " + SHIFT + " .. entry.key, hl.dsp.window.swap({ direction = entry.direction }))
end

for _, entry in ipairs({
  { key = "LEFT", direction = "l" },
  { key = "RIGHT", direction = "r" },
  { key = "UP", direction = "u" },
  { key = "DOWN", direction = "d" },
}) do
  hl.bind(main_mod .. " + " .. entry.key, hl.dsp.focus({ direction = entry.direction }))
  hl.bind(main_mod .. " + SHIFT + " .. entry.key, hl.dsp.window.swap({ direction = entry.direction }))
end

for workspace = 1, 10 do
  local key = tostring(workspace % 10)
  hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = tostring(workspace) }))
  hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(workspace) }))
  hl.bind(main_mod .. " + SHIFT + ALT + " .. key, hl.dsp.window.move({
    workspace = tostring(workspace),
    follow = false,
  }))
end

hl.bind(main_mod .. " + comma", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(main_mod .. " + period", hl.dsp.focus({ workspace = "e+1" }))

for _, entry in ipairs({
  { key = "LEFT", direction = "l" },
  { key = "RIGHT", direction = "r" },
  { key = "UP", direction = "u" },
  { key = "DOWN", direction = "d" },
}) do
  hl.bind(main_mod .. " + SHIFT + ALT + " .. entry.key, hl.dsp.workspace.move({ monitor = entry.direction }))
end

hl.bind(main_mod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(main_mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Scrolling and master layout controls.
hl.bind(main_mod .. " + R", scrolling_only("colresize +conf"))
hl.bind(main_mod .. " + SHIFT + R", scrolling_only("colresize -conf"))
hl.bind(main_mod .. " + SHIFT + I", toggle_scrolling_master)

hl.bind(main_mod .. " + P", master_only("rollprev"))
hl.bind(main_mod .. " + N", master_only("rollnext"))
hl.bind(main_mod .. " + ALT + P", hl.dsp.window.pseudo())
hl.bind(main_mod .. " + m", scrolling_only("promote"))
hl.bind(main_mod .. " + SHIFT + m", scrolling_only("promote"))
hl.bind(main_mod .. " + semicolon", master_only("swapwithmaster auto"))
hl.bind(main_mod .. " + Y", master_only("cyclenext loop"))
hl.bind(main_mod .. " + SHIFT + Y", master_only("cycleprev loop"))
hl.bind(main_mod .. " + a", master_only("addmaster"))
hl.bind(main_mod .. " + z", master_only("removemaster"))
hl.bind(main_mod .. " + u", master_only("mfact exact 0.70"))
hl.bind(main_mod .. " + i", master_only("mfact exact 0.66"))
hl.bind(main_mod .. " + O", master_only("mfact exact 0.50"))

hl.bind(main_mod .. " + SHIFT + n", hl.dsp.window.move({ direction = "l" }))
hl.bind(main_mod .. " + SHIFT + p", hl.dsp.window.move({ direction = "r" }))
hl.bind(main_mod .. " + SHIFT + comma", scrolling_only("swapcol l"))
hl.bind(main_mod .. " + SHIFT + period", scrolling_only("swapcol r"))
hl.bind(main_mod .. " + SLASH", scrolling_only("consume_or_expel prev"))

-- Window state, aspect ratio, resize, mouse, and groups.
hl.bind(main_mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(main_mod .. " + CTRL + F", hl.dsp.window.fullscreen_state({
  internal = 2,
  client = 0,
}))
hl.bind(main_mod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(main_mod .. " + SHIFT + O", pop_window_out)
hl.bind(main_mod .. " + CTRL + BACKSPACE", toggle_single_window_aspect_ratio)

local resize_binds = {
  { mods = "", amount = 100 },
  { mods = "ALT + ", amount = 25 },
  { mods = "CTRL + ", amount = 300 },
}
for _, entry in ipairs(resize_binds) do
  hl.bind(main_mod .. " + " .. entry.mods .. "code:20", hl.dsp.window.resize({ x = -entry.amount, y = 0, relative = true }))
  hl.bind(main_mod .. " + " .. entry.mods .. "code:21", hl.dsp.window.resize({ x = entry.amount, y = 0, relative = true }))
  hl.bind(main_mod .. " + SHIFT + " .. entry.mods .. "code:20", hl.dsp.window.resize({ x = 0, y = -entry.amount, relative = true }))
  hl.bind(main_mod .. " + SHIFT + " .. entry.mods .. "code:21", hl.dsp.window.resize({ x = 0, y = entry.amount, relative = true }))
end

hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(main_mod .. " + G", hl.dsp.group.toggle())
hl.bind(main_mod .. " + ALT + G", hl.dsp.window.move({ out_of_group = true }))
for _, entry in ipairs({
  { key = "LEFT", direction = "l" },
  { key = "RIGHT", direction = "r" },
  { key = "UP", direction = "u" },
  { key = "DOWN", direction = "d" },
}) do
  hl.bind(main_mod .. " + ALT + " .. entry.key, hl.dsp.window.move({ into_group = entry.direction }))
end
hl.bind(main_mod .. " + ALT + TAB", hl.dsp.group.next())
hl.bind(main_mod .. " + ALT + SHIFT + TAB", hl.dsp.group.prev())
hl.bind(main_mod .. " + CTRL + LEFT", hl.dsp.group.prev())
hl.bind(main_mod .. " + CTRL + RIGHT", hl.dsp.group.next())
hl.bind(main_mod .. " + ALT + mouse_down", hl.dsp.group.next())
hl.bind(main_mod .. " + ALT + mouse_up", hl.dsp.group.prev())
for index = 1, 5 do
  hl.bind(main_mod .. " + ALT + " .. tostring(index), hl.dsp.group.active({ index = index }))
end

-- Media controls are delegated to Noctalia. They remain usable while locked.
hl.bind("XF86AudioRaiseVolume", noctalia("volume-up 2"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", noctalia("volume-down 2"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", noctalia("volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", noctalia("mic-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp", noctalia("brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", noctalia("brightness-down"), { locked = true, repeating = true })
hl.bind("SHIFT + XF86MonBrightnessUp", noctalia("brightness-set 100"), { locked = true })
hl.bind("SHIFT + XF86MonBrightnessDown", noctalia("brightness-set 1"), { locked = true })
hl.bind("XF86AudioNext", noctalia("media next"), { locked = true })
hl.bind("XF86AudioPause", noctalia("media toggle"), { locked = true })
hl.bind("XF86AudioPlay", noctalia("media toggle"), { locked = true })
hl.bind("XF86AudioPrev", noctalia("media previous"), { locked = true })
hl.bind("XF86Eject", hl.dsp.exec_cmd("eject"), { locked = true })

hl.bind("SUPER + CTRL + C", noctalia("caffeine-toggle"))
hl.bind("SUPER + CTRL + N", noctalia("nightlight-toggle"))
hl.bind("SUPER + CTRL + L", noctalia("session lock"))

-- Noctalia shell and panel actions.
hl.bind("ALT + TAB", noctalia("window-switcher"))
hl.bind("SUPER + ESCAPE", noctalia("panel-toggle session"))
hl.bind("XF86PowerOff", noctalia("panel-toggle session"), { locked = true })
hl.bind("SUPER + SHIFT + SPACE", noctalia("bar-toggle"))
hl.bind("SUPER + CTRL + SPACE", noctalia("panel-toggle wallpaper"))
hl.bind("SUPER + CTRL + E", noctalia("panel-toggle launcher /emo"))
hl.bind("SUPER + CTRL + Q", noctalia("panel-toggle launcher /calc"))
hl.bind("SUPER + CTRL + A", noctalia("panel-toggle control-center audio"))
hl.bind("SUPER + CTRL + B", noctalia("panel-toggle control-center bluetooth"))
hl.bind("SUPER + CTRL + D", noctalia("panel-toggle control-center monitor"))
hl.bind("SUPER + CTRL + M", noctalia("panel-toggle control-center media"))
hl.bind("SUPER + CTRL + P", noctalia("panel-toggle control-center power"))
hl.bind("SUPER + CTRL + T", noctalia("panel-toggle control-center system"))
hl.bind("SUPER + CTRL + V", noctalia("panel-toggle clipboard"))
hl.bind("SUPER + CTRL + W", noctalia("panel-toggle control-center network"))
hl.bind("SUPER + CTRL + SHIFT + S", noctalia("screenshot-region"))

-- Notification actions that do not displace workspace or layout bindings.
hl.bind("SUPER + CTRL + comma", noctalia("notification-dnd-toggle"))
hl.bind("SUPER + ALT + comma", noctalia("notification-invoke-latest"))
hl.bind("SUPER + ALT + SLASH", noctalia("panel-toggle control-center notifications"))
hl.bind("SUPER + ALT + PERIOD", noctalia("notification-clear-active"))

-- SUPER + CTRL + ALT + SHIFT + SLASH: keybinding reference
