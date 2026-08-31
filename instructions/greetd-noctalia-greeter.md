# greetd and Noctalia Greeter

## Scope

This document defines the planned login path for the EndeavourOS system. It is
an installation and validation procedure; it has not been executed on the
current Omarchy machine.

The target login stack is:

```text
greetd -> noctalia-greeter-session -> Noctalia Greeter -> Hyprland session
```

`greetd` owns the login service and starts a small Wayland compositor for the
greeter. Noctalia Greeter provides the login UI. After authentication, greetd
starts the selected desktop session. Noctalia Shell is started later by
Hyprland and is a separate process.

## Package Strategy

- Install `greetd` from the official Arch/EndeavourOS repositories.
- Install Noctalia v5 from the official `extra` repository.
- Launch Hyprland directly from its Wayland session entry.
- Do not install or introduce UWSM for the initial setup.
- Check for an official or trusted distribution package for
  `noctalia-greeter` before building it.
- If no suitable package is available, build the upstream Greeter from a
  pinned tag rather than from an unpinned `main` checkout.

At the time of research, the latest upstream Greeter tag was `v1.3.0` at
commit `b4e668d4f8aada549d5c990c3a18458fae8be6b9`. Recheck the upstream tags,
Noctalia version, and compatibility before installation.

No official Arch package for `noctalia-greeter` was listed at the time of
research. The upstream project documents a source build and provides the
required system setup script.

## Prerequisites

The following command is for the target EndeavourOS installation, not the
current workstation:

```bash
sudo pacman -S --needed \
  greetd dbus \
  meson gcc just \
  wayland wayland-protocols wlroots0.20 \
  libglvnd freetype2 fontconfig \
  cairo pango harfbuzz \
  libxkbcommon glib2 \
  tomlplusplus nlohmann-json stb \
  libwebp librsvg \
  polkit
```

Noctalia v5 itself should be installed separately from the Arch `extra`
repository. `accountsservice` is optional and should be added if user avatars
are wanted in the Greeter:

```bash
sudo pacman -S --needed noctalia accountsservice
sudo systemctl enable --now accounts-daemon.service
```

The Hyprland session and its Wayland session entry must be installed before
Greeter session discovery is tested. The entry must launch Hyprland directly;
it should not wrap Hyprland in another session manager. Follow
`instructions/hyprland.md` for that package and session step.

## Build From Source

Use the pinned tag identified above. The repository is buildable with Meson and
`just`:

```bash
mkdir -p ~/src
git clone --branch v1.3.0 --depth 1 \
  https://github.com/noctalia-dev/noctalia-greeter.git \
  ~/src/noctalia-greeter
cd ~/src/noctalia-greeter
just configure-release
just build-release
sudo meson install -C build-release
sudo ./scripts/setup_greeter_system.sh
```

The setup script creates or prepares `/var/lib/noctalia-greeter/` and prints a
ready-to-use greetd configuration block. The installed session wrapper is
normally under `/usr/local/bin/` for this source-build path, but its actual
location must be checked:

```bash
command -v noctalia-greeter-session
command -v noctalia-greeter
```

Do not copy only the executable. The Greeter also needs its installed assets.

If a reviewed package becomes available, use its installed paths and package
upgrade mechanism instead of mixing a package installation with a source
installation.

## Configure greetd

Create `/etc/greetd/config.toml` as a root-owned machine configuration. Do not
put this file in the user Stow packages because it contains the installed path,
the system Greeter account, and machine-specific session choices.

Start with the smallest configuration, replacing the command path with the
result of `command -v noctalia-greeter-session`:

```toml
[default_session]
command = "/path/to/noctalia-greeter-session"
user = "greeter"
```

The upstream setup script prints the exact block for the installed path. Use
that output when it differs from the example above.

Do not add a forced `--session` argument initially. Let the Greeter discover
the installed Wayland sessions and confirm the exact session name first:

```bash
noctalia-greeter sessions
noctalia-greeter outputs
```

If a default session is later desired, prefer `[session].default` in
`/var/lib/noctalia-greeter/greeter.toml`. The value must be the desktop-entry
`Name=` shown by `noctalia-greeter sessions`, not the `.desktop` filename.

## Safe Activation

Before enabling greetd:

- Confirm that `Ctrl+Alt+F3` reaches a TTY and that the user can authenticate.
- Keep a bootable EndeavourOS recovery medium available.
- Confirm that no other display manager owns the graphical target.
- Confirm that the Greeter session wrapper and at least one Wayland session are
  executable.
- Check the `greetd` configuration and installed paths one more time.

Only after those checks should greetd be enabled:

```bash
sudo systemctl enable --now greetd.service
```

Do not activate greetd on the existing Omarchy installation as part of this
project. It belongs to the new EndeavourOS system.

## First Login Validation

Test the login path before adding custom Greeter or Noctalia styling:

1. Select the Hyprland session from the Greeter.
2. Log in with the correct password.
3. Confirm that Hyprland starts directly, without UWSM, and without a shell or
   bar yet.
4. Confirm that a TTY remains reachable.
5. Return to the Greeter by logging out.
6. Test a failed password and a second successful login.
7. Test reboot and power-off actions.
8. Test a second monitor if one is available.
9. Inspect failures with `journalctl -u greetd -b`.

Noctalia Shell should be started by Hyprland only after this login path works.

## Recovery

If the Greeter or session fails, switch to a TTY with `Ctrl+Alt+F3` through
`Ctrl+Alt+F12`, log in, and inspect the service:

```bash
sudo journalctl -u greetd -b
sudo systemctl status greetd.service
```

After correcting `/etc/greetd/config.toml`, restart greetd from the TTY:

```bash
sudo systemctl restart greetd.service
```

If it must be stopped while investigating:

```bash
sudo systemctl disable --now greetd.service
```

Keep TTY access as the recovery path. Do not install a second display manager
just to mask an untested Greeter configuration.

## Greeter and Shell Synchronization

After both Noctalia v5 and Noctalia Greeter work independently, use Noctalia
Shell's **Settings -> Security -> Noctalia Greeter -> Sync Now** action to copy
selected appearance data. The sync requires administrative authorization through
polkit and can copy:

- Wallpaper, including per-output wallpapers.
- Palette and light/dark theme mode.
- Shell font family.
- Corner-radius scale.
- Session actions and power-command overrides.
- Monitor transforms, scales, and multi-monitor layout.

The synchronized data belongs under `/var/lib/noctalia-greeter/`. It is runtime
system state and must not be managed through GNU Stow. Declarative Greeter
configuration in `greeter.toml` takes precedence over synchronized values.

## Later Configuration Work

The following are deliberately not part of this first login step:

- Custom Greeter styling.
- A forced default session.
- Monitor-specific output configuration.
- Automatic Greeter appearance synchronization.
- Noctalia Shell dotfiles.
- Hyprland keybindings for Noctalia IPC.

Each will be tested after the base `greetd -> Noctalia Greeter -> Hyprland`
path is reliable.

## Sources

- [Noctalia installation](https://docs.noctalia.dev/noctalia/getting-started/installation/)
- [Running Noctalia](https://docs.noctalia.dev/noctalia/getting-started/running-the-shell/)
- [Noctalia Greeter documentation](https://docs.noctalia.dev/greeter/)
- [Noctalia Greeter source](https://github.com/noctalia-dev/noctalia-greeter)
- [Noctalia Greeter v1.3.0](https://github.com/noctalia-dev/noctalia-greeter/tree/v1.3.0)
- [Arch `greetd` package](https://archlinux.org/packages/extra/x86_64/greetd/)
