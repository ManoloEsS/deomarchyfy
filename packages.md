# Packages

## Purpose

This is the package inventory for the EndeavourOS workstation. It separates
packages normally provided by the EndeavourOS setup from the applications and
tools selected for this configuration.

Prefer official EndeavourOS/Arch packages. Use the AUR only when an official
package is not available, and use an upstream installer or binary only when
neither repository is suitable.

Package availability and names must be checked again during installation. This
is especially important for AUR packages and rapidly changing developer tools.

## EndeavourOS Baseline

These are the baseline tools and services expected when the recommended Online
installer selections are kept (`No Desktop` plus the common package groups).
They are profile-dependent; check what is already installed before adding them
again during Phase 2 of the installation runbook:

| Component | Package or command | Purpose |
| --- | --- | --- |
| Browser | `firefox` | Free and open-source web browser |
| Package manager | `pacman` | Official Arch and EndeavourOS package management; already part of the system |
| AUR helper | `yay` | Builds and installs packages from the Arch User Repository |
| Firewall | `firewalld` | Host firewall using the default `home` zone |
| Multimedia | `pipewire`, `pipewire-pulse`, `pipewire-alsa`, `pipewire-jack`, `wireplumber` | Audio and video capture, playback, and compatibility layers |
| Hardware tool | `eos-hwtool` | EndeavourOS hardware, VM-driver, and GPU-driver management |
| Initramfs | `dracut` | Builds initramfs images |
| Power profiles | `power-profiles-daemon` | Provides power behavior profiles to the desktop |
| System monitor | `glances` | Cross-platform system monitoring |

The package manager itself is not installed as a separate application. `yay`
is an AUR helper, not a replacement for `pacman`; use `pacman` for official
packages.

`eos-hwtool` is EndeavourOS-specific and may not appear in a plain Arch package
database. Verify that it is present in the selected EndeavourOS profile rather
than attempting to install it from an unrelated repository.

## Desktop Runtime

These packages support the chosen direct-session path:

| Package | Purpose |
| --- | --- |
| `hyprland` | Wayland compositor and window manager |
| `noctalia` | Desktop shell |
| `greetd` | Login service |
| `dbus` | Session and system bus required by the greeter and desktop services |
| `nautilus` | File manager launched by the Hyprland bindings |
| Noctalia Greeter | Login and session-selection interface; verify the upstream installation method |
| `xdg-desktop-portal` | Generic desktop portal service |
| `xdg-desktop-portal-hyprland` | Hyprland screen sharing and portal integration |
| `networkmanager` | Network management for Noctalia |
| `tailscale` | Private mesh networking and remote access |
| `bluez`, `bluez-utils` | Bluetooth support |
| `upower` | Battery and power-device information |
| `polkit` | Privileged desktop authentication |
| `power-profiles-daemon` | Power-profile integration |

Noctalia owns the bar, launcher, notifications, lock screen, idle handling,
night light, wallpaper, OSD, and control center. Do not add Waybar, Mako,
Walker, fuzzel, hyprlock, hypridle, or hyprsunset for those responsibilities.

## Personal Tools

| Tool | Package or installation source | Purpose |
| --- | --- | --- |
| Ghostty | `ghostty`, official repository | Default terminal emulator |
| tmux | `tmux`, official repository | Persistent terminal sessions |
| Neovim | `neovim`, official repository | Default text editor |
| Jujutsu | `jujutsu`, official repository | Version control and change management |
| mise | `mise`, official repository | Runtime and tool version management |
| Starship | `starship`, official repository | Interactive shell prompt |
| zoxide | `zoxide`, official repository | Frecency-based directory navigation |
| eza | `eza`, official repository | Enhanced directory listings |
| fzf | `fzf`, official repository | Interactive file and command selection |
| bat | `bat`, official repository | Syntax-highlighted file and man-page previews |
| Docker | `docker`, official repository | Container tooling |
| OpenCode | Verify current official, AUR, or upstream source | Coding agent CLI |
| Herdr | Official upstream installer or release binary | Persistent runtime for coding-agent terminals |
| Spotify | Verify current AUR package | Music player |
| Brave | Verify current AUR package, commonly `brave-bin` | Chromium-based browser |
| Zen Browser | Verify current AUR package, commonly `zen-browser-bin` | Firefox-based browser |

Herdr currently documents a Linux installer at:

```bash
curl -fsSL https://herdr.dev/install.sh | sh
```

Prefer reviewing upstream installation changes and using a release binary when
that provides a clearer update and verification path. Do not manage Herdr with
`pacman` unless a maintained Arch package becomes available.

## Supporting Tools

These are small but useful dependencies for the workstation and installation
workflow:

| Package | Purpose |
| --- | --- |
| `git` | Source control and compatibility with existing repositories |
| `curl` | Downloads, API access, and upstream installers |
| `base-devel` | Build tools required by many AUR packages |
| `ca-certificates` | TLS certificate trust for network clients |
| `bash-completion` | System Bash completions |
| `less` | Pager for tmux help and terminal output |
| `xdg-utils` | Provides `xdg-open` for the Bash `open` helper |
| `util-linux` | Provides `eject`, `col`, and `setsid`; normally part of the base system |
| `ttf-jetbrains-mono-nerd` | Font used by Ghostty and terminal applications |
| `zram-generator` | Creates compressed zram swap devices for non-hibernating systems |
| `inotify-tools` | File-change notifications for `rsw` |
| `rsync` | Directory synchronization for `rsw` |
| `openssh` | `scp` and SSH transport for `sff` and `rsw` |
| `accountsservice` | Optional user and avatar data for Noctalia Greeter |
| `stow` | Applies the repository's user configuration packages as symlinks |

## Installation Order

Update the system before installing the selected packages:

```bash
sudo pacman -Syu
```

Install official repository packages with the repository script. It uses
`--needed` and can be run again safely:

```bash
./scripts/01-install-packages.sh
```

Use `--no-upgrade` when the system was already updated separately. Install AUR
packages only after `yay` is available, and verify the package source before
confirming each build:

```bash
yay -S spotify brave-bin zen-browser-bin
```

OpenCode and Herdr are intentionally not included in that command because their
distribution channels can change independently of the Arch package database.

## Services

Run the service script as the normal user from the repository. Its default action
enables NetworkManager, Firewalld with the `home` zone, power profiles, and the
`fstrim.timer`:

```bash
./scripts/02-enable-services.sh
```

Enable optional services explicitly:

```bash
./scripts/02-enable-services.sh --ssh --tailscale --bluetooth
./scripts/02-enable-services.sh --docker
./scripts/02-enable-services.sh --accountsservice
```

The `--ssh` option requires `~/.ssh/authorized_keys` to contain a public key and
adds the SSH service to Firewalld's `home` zone. Tailscale authentication remains
separate:

```bash
sudo tailscale up
tailscale status
tailscale ip
```

The script intentionally does not enable `greetd`; it must be activated only
after the Greeter and direct Hyprland session have been tested. PipeWire and
WirePlumber are normally user-session services. Verify them from a graphical
session rather than creating duplicate system services:

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
```

## zram

This setup does not use disk swap because hibernation is not required. Install
`zram-generator`, then create `/etc/systemd/zram-generator.conf` with:

```ini
[zram0]
zram-size = ram
compression-algorithm = zstd
```

Reboot to let systemd generate and activate the zram swap unit. Verify it with
`swapon --show` and `zramctl`. Do not enable
`systemd-zram-setup@zram0.service` manually; it is generated from this
configuration.

## Firewall

EndeavourOS/Arch provides the kernel packet-filtering framework, but a firewall
manager is not automatically enabled merely because the operating system is
installed. This setup uses `firewalld` and its `home` zone because the machine
will remain on a trusted home network. Services are still allow-listed rather
than opened automatically.

Verify the active zone after enabling it:

```bash
firewall-cmd --get-default-zone
firewall-cmd --get-active-zones
firewall-cmd --list-all --zone=home
```

SSH is intentionally enabled in this setup. Before enabling remote access,
install the user's public key in `~/.ssh/authorized_keys`, then run:

```bash
./scripts/02-enable-services.sh --ssh
firewall-cmd --list-services --zone=home
```

If SSH is not needed on a particular machine, skip `sshd.service` and do not
add the firewall service. Do not expose any other incoming service merely
because its package is installed.

## Optional Services

Docker is installed for the `docker` shell shortcut but its daemon does not need
to run unless containers are being used:

```bash
./scripts/02-enable-services.sh --docker
```

Log out and back in after adding the user to the `docker` group. The group grants
root-equivalent control over the host through the Docker socket.

If user avatars are wanted in Noctalia Greeter, install and enable
`accountsservice` separately:

```bash
sudo pacman -S --needed accountsservice
./scripts/02-enable-services.sh --accountsservice
```

## Default Editor

Neovim is the default editor for interactive tools and programs that honor the
standard environment variables:

```bash
EDITOR=nvim
VISUAL=nvim
GIT_EDITOR=nvim
SUDO_EDITOR=nvim
```

Git should also be configured explicitly:

```bash
git config --global core.editor nvim
```

Jujutsu uses the same environment by default. If an explicit Jujutsu config is
later added, its editor should remain `nvim` rather than introducing a second
editor choice.

## Verification

After installation, verify the important commands and services:

```bash
command -v ghostty
command -v eos-hwtool
command -v herdr
command -v jj
command -v nvim
command -v opencode
command -v tmux
firewall-cmd --state
powerprofilesctl get
dracut --version
wpctl status
```

The direct Hyprland session, Noctalia startup, portal behavior, and the
Hyprland keybindings are validated separately in `instructions/hyprland.md` and
`shell.md`.
