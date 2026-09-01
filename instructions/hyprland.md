# Hyprland

## Decision

Use the official Arch package and launch **Hyprland directly** from the
Wayland session entry selected by Noctalia Greeter.

The target session path is:

```text
greetd -> Noctalia Greeter -> hyprland.desktop -> Hyprland -> Noctalia Shell
```

Do not use the `hyprland-uwsm.desktop` entry and do not install UWSM for the
initial system. The Arch Hyprland package ships both entries, so selecting the
direct `Hyprland` session must be explicit.

Hyprland owns the compositor. It is responsible for windows, workspaces,
monitors, input, compositor effects, keybindings, and compositor startup. It
does not provide the desktop shell; Noctalia will be started from Hyprland's
configuration after the direct session works.

## Scope

This document covers package installation and direct-session validation. It
does not apply changes to the current Omarchy machine. The curated Hyprland
dotfiles live in the project Stow package.

Use Hyprland's native Lua configuration for the curated setup. Hyprland 0.55+
deprecated the classic `hyprland.conf` syntax in favor of Lua, so the Stow
package uses `hyprland.lua` and modules beside it under `~/.config/hypr/`.

## Package Strategy

Install Hyprland from the official Arch/EndeavourOS repositories:

```bash
sudo pacman -S --needed hyprland
```

At the time of research, Arch `extra` listed Hyprland `0.56.2-1`. Recheck the
available version during installation rather than pinning this documentation's
current package version.

The package provides:

- `/usr/bin/Hyprland` and the lowercase executable alias.
- `hyprctl` for compositor inspection and control.
- XWayland support through its package dependencies.
- `/usr/share/wayland-sessions/hyprland.desktop` for the direct session.
- `/usr/share/wayland-sessions/hyprland-uwsm.desktop` for the excluded UWSM
  session.

Do not add the following components at this stage:

- `uwsm`.
- Waybar, because Noctalia owns the bar.
- Mako or another notification daemon, because Noctalia owns notifications.
- Walker, fuzzel, or another launcher, because Noctalia owns the launcher.
- `hyprlock` or `hypridle`, because Noctalia owns locking and idle behavior.
- `hyprsunset`, because Noctalia owns night light.
- `hyprshutdown`, unless a later recovery or shutdown requirement justifies it.

## Desktop Portals

The Hyprland portal backend is an integration dependency, not a compositor
replacement. Add it when portal features are needed:

```bash
sudo pacman -S --needed xdg-desktop-portal-hyprland
```

This supports Hyprland-specific screen sharing and related portal operations.
Install `xdg-desktop-portal-gtk` later if GTK file chooser or fallback portal
behavior requires it. Do not add both merely as duplicate replacements; the
portal configuration should have one intentional backend for each operation.

Portal services are normally activated through D-Bus. Do not create a custom
systemd service for the portal during this step.

## Verify the Direct Session

After Hyprland and the Greeter are installed, verify the package and session
entries before enabling the login service:

```bash
command -v Hyprland
command -v hyprctl
test -x /usr/bin/Hyprland
test -f /usr/share/wayland-sessions/hyprland.desktop
noctalia-greeter sessions
```

The Greeter must show a direct `Hyprland` session. If it shows both direct and
UWSM-managed entries, select the direct one. Do not select a session whose
label or desktop entry identifies it as UWSM-managed.

The Arch package may also ship the excluded UWSM entry. Its presence does not
mean UWSM is installed or selected.

## First Direct Login

The login service must already be configured according to
`instructions/greetd-noctalia-greeter.md`, but Noctalia Shell should not be
customized yet.

1. Select the direct `Hyprland` session in Noctalia Greeter.
2. Log in with the normal user account.
3. Confirm that Hyprland starts without UWSM.
4. Confirm that `hyprctl version` and `hyprctl monitors` work from the session.
5. Confirm that a TTY remains reachable.
6. Log out and confirm that greetd returns to Noctalia Greeter.
7. Reboot and repeat the login once.

An empty or mostly empty desktop is expected until the Hyprland configuration
and Noctalia autostart are applied. Do not compensate by installing a second
shell or bar.

## Noctalia Startup

Noctalia must be launched by Hyprland's compositor startup mechanism, not by
greetd and not by Bash. The native Lua entrypoint uses
`hl.on("hyprland.start", ...)` to start Noctalia.

The required order is:

1. greetd starts Noctalia Greeter.
2. Noctalia Greeter authenticates the user and starts the direct Hyprland
   session.
3. Hyprland initializes monitors, input, and compositor state.
4. Hyprland starts Noctalia once through compositor autostart.
5. Noctalia provides the bar, launcher, notifications, lock, idle behavior,
   wallpaper, OSD, and selected system controls.

Do not start Noctalia both from Hyprland and from a user service. One startup
owner prevents duplicate bars, notification daemons, and panel surfaces.

The application launcher is opened through Noctalia's v5 IPC command:

```bash
noctalia msg panel-toggle launcher
```

The Hyprland `SUPER + SPACE` binding uses this command. Do not use the older
`noctalia msg launcher toggle` form.

## Environment Boundaries

The direct session relies on greetd, PAM, the selected Wayland desktop entry,
and Hyprland to establish the graphical session environment. There is no UWSM
environment-preparation or cleanup layer.

Noctalia and graphical applications still depend on the underlying system
services and portals documented in `shell.md`. Direct Hyprland does not remove
the need for D-Bus, PipeWire/WirePlumber, NetworkManager, BlueZ, polkit,
portals, or the user systemd manager where those features are used.

## Recovery

If the direct session fails, switch to a TTY with `Ctrl+Alt+F3` through
`Ctrl+Alt+F12` and inspect the login service and current boot:

```bash
sudo journalctl -u greetd -b
sudo systemctl status greetd.service
```

If the problem is in a newly created Hyprland configuration, correct or move
only that configuration from the TTY. Do not alter the Greeter or install UWSM
as an untested workaround.

The recovery target remains:

```text
TTY -> inspect greetd/Hyprland logs -> correct the selected direct session
```

## Later Configuration Work

After the direct session is reliable, apply the curated Hyprland Stow package
under:

```text
dotfiles/hyprland/.config/hypr/
```

The current package provides the native Lua entrypoint, monitor rules, combined
look-and-feel/input overrides, and reviewed native keybindings. Remaining
configuration work will validate and document:

- Window rules and workspace rules.
- Noctalia autostart and IPC commands on the target system.
- Layer rules for Noctalia surfaces.
- XWayland and portal behavior.
- Noctalia v5 IPC actions, including the launcher panel toggle.

### Compositor Animation Profile

Hyprland compositor animations are owned by
`dotfiles/hyprland/.config/hypr/looknfeel.lua`. The current profile uses the
Omarchy v4.0.2 timing and curve values for window, border, layer, fade, and
special-workspace transitions while leaving workspace changes instant. The
profile is deliberately separate from Noctalia's shell animations: changing
Noctalia tiles or panels does not change Hyprland window animations.

After changing the Lua package, apply the links with Stow and reload Hyprland:

```bash
./scripts/03-stow-configs.sh --restow hyprland
hyprctl reload
hyprctl configerrors
```

Keep `animations` as a top-level Hyprland configuration section. Placing it
inside `general` produces an `unknown config key 'general.animations.enabled'`
error. Noctalia's separate animation control is managed by the reviewed Stow
file at `~/.config/noctalia/config.toml`; the audited target currently has
`[shell.animation] enabled = false`. GUI-managed values such as the shell speed
remain in Noctalia's state file and are not part of the repository.

The current Omarchy Hyprland files are reference material only. Do not copy
Omarchy includes, generated state, wrappers, or paths into the new package.

## Terminal Working Directory

The `SUPER + RETURN` binding launches
`~/.local/bin/deomarchyfy-launch-terminal`. For a focused Ghostty window, the
launcher uses Ghostty's `+new-window` action and its reported shell CWD. For
another terminal, it walks the active window's process tree and uses the first
valid shell CWD, falling back to `$HOME`.

This avoids an Omarchy or UWSM dependency. Ghostty's CWD reporting and
window/tab/split inheritance are enabled in its Stow configuration. Test the
behavior after applying the package by changing directories in a terminal,
pressing `SUPER + RETURN`, and confirming the new terminal starts there.

## Sources

- [Hyprland installation](https://wiki.hypr.land/Getting-Started/Installation/)
- [Arch Hyprland package](https://archlinux.org/packages/extra/x86_64/hyprland/)
- [Arch Hyprland file list](https://archlinux.org/packages/extra/x86_64/hyprland/files/)
- [Arch Hyprland portal backend](https://archlinux.org/packages/extra/x86_64/xdg-desktop-portal-hyprland/)
- [Noctalia Hyprland integration](https://docs.noctalia.dev/noctalia/compositor-settings/hyprland/)
- [Noctalia Greeter](https://docs.noctalia.dev/greeter/)
