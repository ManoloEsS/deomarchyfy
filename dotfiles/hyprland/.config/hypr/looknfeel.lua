-- Personal Hyprland look-and-feel and input overrides.

local active_border_color = {
  colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
  angle = 45,
}

hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 3,
    border_size = 3,
    col = {
      active_border = active_border_color,
    },
    layout = "scrolling",
    no_focus_fallback = true,
  },

  binds = {
    window_direction_monitor_fallback = false,
  },

  master = {
    allow_small_split = false,
    special_scale_factor = 1.0,
    mfact = 0.7,

    new_status = "slave",
    new_on_top = false,
    new_on_active = "none",

    orientation = "right",
    slave_count_for_center_master = 2,
    center_master_fallback = "left",

    smart_resizing = true,
    drop_at_cursor = true,
    always_keep_position = false,
  },

  decoration = {
    rounding = 0,
    blur = {
      enabled = true,
      size = 5,
      ignore_opacity = true,
      passes = 1,
      special = true,
      brightness = 0.9,
      contrast = 0.75,
      noise = 0.01,
      vibrancy = 0.1696,
    },
  },

  scrolling = {
    column_width = 0.5,
    explicit_column_widths = "0.29, 0.49, 0.69, 0.99",
  },

  input = {
    repeat_rate = 40,
    repeat_delay = 250,
    accel_profile = "flat",
    touchpad = {
      scroll_factor = 0.4,
      -- Disable touchpad input while typing.
      disable_while_typing = true,
      drag_3fg = 1,
    },
  },
})
