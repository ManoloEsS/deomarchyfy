# Desktop Shell

## Decision

Use **Noctalia v5** as the desktop shell for Hyprland.

Noctalia v5 is available for Arch Linux through the official `extra` repository.
At the time of this research, the Arch package database listed
`5.0.0_beta.10-1`; the package version must be checked again when the system is
installed. The legacy Quickshell-based v4 implementation is no longer
maintained and will not be used.

Noctalia will replace the Omarchy shell layer, not Hyprland or the underlying
Linux services. The goal is to use Noctalia's built-in functionality first and
add separate tools only when Noctalia does not provide the required behavior.

## Noctalia Shell Responsibilities

The following responsibilities are provided by Noctalia v5 itself or through
its documented integrations:

| Area | Noctalia capability | Initial status |
| --- | --- | --- |
| Bar | Per-monitor bars with configurable placement, spacing, widgets, styling, auto-hide, and workspace display | Core |
| Notifications | Freedesktop notification daemon, toast display, notification history, filtering, sounds, and Do Not Disturb | Core |
| Lock screen | Session lock surface, password entry, lock actions, and lock-related UI | Core |
| Idle handling | Named idle behaviors for lock, screen-off, suspend, lock-and-suspend, or custom commands | Core |
| Night light | Scheduled or forced color-temperature changes through the Wayland `wlr-gamma-control` protocol | Core |
| Launcher | Application search and launch, calculator, emoji, wallpaper, session actions, open-window search, dmenu mode, and plugin providers | Core |
| Control Center | Home, media, audio, monitor brightness, system, network, Bluetooth, weather, calendar, notifications, screen time, and power tabs | Core, with optional tabs |
| OSD | Volume, microphone, brightness, Wi-Fi, Bluetooth, power profile, caffeine, night light, lock keys, keyboard layout, media, privacy, and keyboard-backlight popups | Core |
| Wallpaper | Wallpaper picker, per-monitor wallpaper, transitions, automatic rotation, theme-aware directories, and wallpaper launcher provider | Core |
| Backdrop | Blurred and tinted wallpaper backdrop for compositor overview modes | Optional; disabled by default |
| Dock | Pinned and running applications, magnification, auto-hide, and workspace-aware behavior | Optional; disabled by default |
| Audio | PipeWire output/input volume, mute, device selection, streams, and optional UI sounds | Core controls |
| Brightness | Kernel backlight control and optional `ddcutil` support for external monitors | Core where hardware supports it |
| Media | MPRIS player discovery, artwork, playback controls, player selection, and media OSD | Core integration |
| Network | NetworkManager-backed Wi-Fi and connection status | Core integration |
| Bluetooth | Adapter state, paired devices, connections, and pairing flows | Core integration |
| Power | UPower battery state, power profiles, battery health, connected-device batteries, suspend, reboot, and shutdown | Core integration |
| System monitor | CPU, memory, network, disk, temperature, GPU, and VRAM statistics | Optional |
| Screenshots | Region or fullscreen capture, PNG output, clipboard copy, and optional pipe-to-command processing | Core integration |
| Clipboard | Clipboard history and panel with encrypted persistent storage | Optional; review privacy impact |
| Calendar | Read-only ICS, CalDAV, iCloud, and Google Calendar integration with encrypted event cache | Optional; not part of the minimal base |
| Weather | Current conditions and six-day forecast through Open-Meteo | Optional |
| Screen time | Foreground application usage tracking and charts | Optional; disabled by default |
| Theming | Built-in themes, palettes, light/dark mode, wallpaper-derived colors, application theme templates, and font settings | Core appearance layer |
| Settings | Graphical settings window, configuration reload, diagnostics, and configuration export | Core |
| IPC and plugins | Commands for shell surfaces/system controls and installable custom widgets/providers | Use only when needed |

Noctalia's controls operate through existing system interfaces. For example,
audio still depends on PipeWire, network controls still depend on
NetworkManager, battery information comes from UPower, Bluetooth uses the
system Bluetooth stack, and power profiles require `power-profiles-daemon`.
Noctalia provides the UI and control layer; it does not replace those system
services.

## Greeter Decision

**Noctalia Greeter is a separate component from Noctalia Shell.** It is a login
screen built specifically for `greetd`. It is not a desktop shell, compositor,
or display manager.

Use **`greetd` with Noctalia Greeter** as the login path for this setup. Do not
add GDM or another display manager to the target system just to provide a
fallback login screen.

Noctalia Greeter can provide:

- User selection and password authentication.
- Wayland session selection.
- Color-scheme selection.
- Keyboard-only login navigation.
- Wallpaper, palette, theme mode, font, corner-radius, session-action, and
  monitor-layout synchronization from Noctalia Shell.
- User avatars when `accountsservice` is available.

The Arch package database did not contain a `noctalia-greeter` package at the
time of this research. The installation instructions must therefore check for
an EndeavourOS/Arch package first and use the documented upstream installation
method if necessary. This is an implementation detail, not a reason to switch
the login-manager decision.

The greeter must be evaluated separately from the shell because it has its own
configuration, permissions, logs, and failure modes. Recovery will be provided
through a TTY and a documented alternate-session procedure while the greeter is
being tested.

Noctalia Greeter requires `greetd`, D-Bus, and polkit. Its synchronized files
are installed under `/var/lib/noctalia-greeter/` and are not user dotfiles to be
managed through Stow.

## Ownership Boundaries

| Responsibility | Owner |
| --- | --- |
| Window management, layouts, window rules, monitor modes and positions, input behavior, compositor animations, and compositor keybindings | Hyprland |
| Bar, launcher, notifications, lock screen, idle actions, night light, wallpaper, OSD, control center, and shell appearance | Noctalia |
| Login screen and session selection | `greetd` plus Noctalia Greeter |
| Audio transport and devices | PipeWire and WirePlumber |
| Network connections | NetworkManager |
| Bluetooth hardware and pairing | BlueZ |
| Battery and power-profile data | UPower and `power-profiles-daemon` |
| Authentication prompts | One polkit agent, preferably Noctalia's only if no other agent is installed |
| Screen sharing and file chooser portals | `xdg-desktop-portal` and the selected Wayland/GTK backend |
| Package management, updates, backups, filesystem snapshots, and recovery | EndeavourOS/Arch system administration |
| Shell prompt, command history, completion, navigation, and developer aliases | Bash configuration |

Noctalia Greeter will launch Hyprland directly through the selected Wayland
session entry. UWSM will not be part of the initial system. This keeps the
session path to `greetd -> Noctalia Greeter -> Hyprland` without an additional
session manager.

Hyprland will start Noctalia through compositor autostart. Noctalia-related
keybindings will be declared in Hyprland and will call Noctalia IPC where
appropriate. Noctalia will not be launched from `.bashrc`.

## Minimal Initial Profile

The first configuration should enable only the desktop functions needed for a
usable session:

- One top bar on each monitor.
- Workspaces, clock, audio, network, Bluetooth, notifications, and session
  controls.
- Application launcher.
- Notifications and Do Not Disturb.
- Lock screen and explicit idle policies.
- Night light through Noctalia's gamma-control integration.
- Wallpaper management.
- Volume, microphone, brightness, and session OSDs.
- Control Center.
- Screenshot support.

The following should remain disabled or deferred until there is a demonstrated
need:

- Dock.
- Backdrop.
- Weather and calendar synchronization.
- Screen-time tracking.
- Desktop widgets.
- Third-party plugins.
- External WAN IP lookups.
- UI sounds.
- Noctalia telemetry.
- Native Noctalia polkit agent when another agent is already present.
- Persistent clipboard history until its encrypted storage and privacy behavior
  are reviewed.

## Configuration and Stow

Noctalia has two configuration layers:

- Handwritten configuration in `~/.config/noctalia/`.
- GUI-managed overrides in `~/.local/state/noctalia/settings.toml`.

Noctalia loads handwritten `*.toml` files from the configuration directory in
alphabetical order, then applies GUI-managed state last. The state file can
therefore override a value in the Stow-managed configuration.

The future Stow package should contain only reviewed handwritten files, for
example:

```text
dotfiles/noctalia/.config/noctalia/
```

Do not Stow Noctalia's runtime state, generated plugin files, downloaded
catalogs, encrypted caches, calendar credentials, or storage keys. Use
`noctalia config validate` before applying a curated configuration, and use
`noctalia config export` when recording the effective configuration for review.

## Avoid Duplicate Owners

The target should not run multiple components for the same responsibility.
Unless a later decision requires them, do not add:

- Waybar alongside Noctalia's bar.
- Mako or another notification daemon alongside Noctalia's notification daemon.
- Walker, fuzzel, or another launcher alongside Noctalia's launcher.
- `hyprlock` or `hypridle` alongside Noctalia's lock and idle behavior.
- `hyprsunset` alongside Noctalia's night light.
- A second polkit authentication agent.
- A separate dock when Noctalia's dock is enabled.

## Validation Requirements

Before custom styling or extensive keybindings are added:

1. Start Noctalia with its defaults from a Hyprland session.
2. Confirm that it starts once and restarts cleanly without duplicate surfaces.
3. Validate the configuration with `noctalia config validate`.
4. Test notifications, history, Do Not Disturb, launcher, bar widgets, volume,
   microphone, brightness, Bluetooth, network, wallpaper, screenshots, lock,
   idle, suspend, and night light.
5. Test both monitors and output hotplug behavior.
6. Test logout and recovery to the login screen.
7. Test Noctalia Greeter failed authentication, session selection, reboot,
   power-off, and fallback access through a TTY or alternate session.

Only after the default behavior is understood should the current Omarchy shell
settings be compared and selectively reproduced.

## Sources

- [Noctalia v5 overview](https://docs.noctalia.dev/noctalia/)
- [Arch installation](https://docs.noctalia.dev/noctalia/getting-started/installation/)
- [Running Noctalia](https://docs.noctalia.dev/noctalia/getting-started/running-the-shell/)
- [Hyprland integration](https://docs.noctalia.dev/noctalia/compositor-settings/hyprland/)
- [Configuration model](https://docs.noctalia.dev/noctalia/configuration/)
- [Shell configuration](https://docs.noctalia.dev/noctalia/configuration/shell/)
- [Bars and widgets](https://docs.noctalia.dev/noctalia/bar/)
- [Launcher](https://docs.noctalia.dev/noctalia/launcher/)
- [Control Center](https://docs.noctalia.dev/noctalia/control-center/)
- [Idle service](https://docs.noctalia.dev/noctalia/services/idle/)
- [Night light service](https://docs.noctalia.dev/noctalia/services/night-light/)
- [Notifications service](https://docs.noctalia.dev/noctalia/services/notifications/)
- [System controls and IPC](https://docs.noctalia.dev/noctalia/ipc/system-controls/)
- [Noctalia Greeter](https://docs.noctalia.dev/greeter/)
- [Arch Noctalia package](https://archlinux.org/packages/extra/x86_64/noctalia/)
- [Noctalia Greeter source repository](https://github.com/noctalia-dev/noctalia-greeter)
