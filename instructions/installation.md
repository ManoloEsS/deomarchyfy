# EndeavourOS Installation and Setup

## Scope

This is the end-to-end procedure for a clean EndeavourOS installation. It
separates work performed by the EndeavourOS installer, normal post-install
administration, and this repository's user configuration.

Noctalia configuration is intentionally manual. The Stow script does not touch
Noctalia's handwritten configuration, generated state, plugins, or Greeter
state.

The intended session path is:

```text
greetd -> Noctalia Greeter -> direct Hyprland session -> Noctalia Shell
```

Read `OS.md`, `packages.md`, `instructions/hyprland.md`, and
`instructions/greetd-noctalia-greeter.md` before changing the target system.

## Phase 1: Installer Decisions

Use the current EndeavourOS installer and recheck its options before confirming
the installation. Installer labels and defaults can change.

### Firmware and Disk

- Boot the installer in UEFI mode. Confirm this from the firmware menu rather
  than assuming the boot mode.
- Use GPT for a UEFI installation.
- For a single-user machine, prefer full-disk LUKS2 encryption unless there is
  a specific need for unattended boot.
- Prefer Btrfs with a documented snapshot layout when snapshots and recovery are
  part of the maintenance plan. Use ext4 instead when a simple, low-maintenance
  filesystem is more important than snapshots.
- Do not create a separate `/home` filesystem merely by habit. With Btrfs,
  choose subvolumes deliberately so root rollback does not unexpectedly include
  or exclude user data.
- Use zram for normal swap if hibernation is not required. Hibernation needs a
  real swap area or correctly configured swapfile, sufficient capacity, and
  resume configuration in the initramfs and kernel command line.
- Keep the EFI System Partition outside the encrypted container and do not
  format an existing EFI partition without confirming that it is safe.

### Bootloader

- Prefer systemd-boot for a straightforward single-OS UEFI machine.
- Prefer GRUB when multi-boot detection, legacy firmware support, or a more
  flexible boot menu is required.
- Record the selected bootloader and disk layout. Future recovery instructions
  depend on this choice.

### Installer Profile

- Choose the smallest profile that provides the required network and hardware
  support. Do not install a second full desktop environment.
- Create the normal user account during installation and use it for Stow and
  AUR work. Do not use root for user configuration.
- Enable networking in the installer if needed, but treat it as a first-boot
  dependency check rather than proof that the final service configuration is
  correct.
- Let the installer install its normal kernel, firmware, microcode, initramfs,
  and package-manager baseline. Do not duplicate those blindly in the first
  package command.

After reboot, confirm that the system boots from the intended disk and that the
normal user can reach a TTY. Do not enable the new graphical login service yet.

## Phase 2: First Boot Baseline

Run these commands from a TTY or an existing graphical terminal on the new
system. Review the transaction before accepting it.

```bash
sudo pacman -Syu
sudo pacman -S --needed git stow
```

Install the official package inventory from `packages.md`:

```bash
sudo pacman -S --needed \
  base-devel bluez bluez-utils ca-certificates curl dbus dracut firewalld \
  bash-completion bat docker eza firefox fzf git glances ghostty greetd \
  hyprland inotify-tools jujutsu mise neovim networkmanager noctalia tailscale \
  less nautilus openssh pipewire pipewire-alsa pipewire-jack pipewire-pulse \
  polkit power-profiles-daemon python-gobject rsync starship stow tmux upower \
  wireplumber ttf-jetbrains-mono-nerd xdg-desktop-portal \
  xdg-desktop-portal-hyprland xdg-utils zoxide
```

Omit packages already provided by the selected EndeavourOS profile. `--needed`
keeps installed packages from being reinstalled. Recheck package names before
running this command because Arch repositories and profiles change.

Install AUR packages only after the official package update is complete and an
AUR helper is available:

```bash
yay -S spotify brave-bin zen-browser-bin
```

Review PKGBUILDs and update behavior before confirming AUR builds. Install
OpenCode and Herdr through their current documented upstream methods rather
than assuming their distribution channel is stable.

## Phase 3: Hardware and Core Services

### Hardware

- Use `eos-hwtool` when it is present in the EndeavourOS installation for
  hardware and GPU-driver recommendations.
- Confirm that the CPU microcode package matches the processor vendor.
- Confirm that `linux-firmware` is installed.
- Install proprietary GPU drivers only when the hardware and workload require
  them. Reboot after driver changes and test the Wayland session before adding
  desktop customization.
- Test display outputs, audio, suspend, Bluetooth, and networking before
  enabling the graphical login path.

Useful checks:

```bash
command -v eos-hwtool
dracut --version
wpctl status
nmcli general status
```

### Services

Enable only services that are installed and needed. NetworkManager is normally
already enabled by EndeavourOS; repeating `enable --now` is harmless.

```bash
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now firewalld.service
sudo systemctl enable --now power-profiles-daemon.service
sudo systemctl enable --now tailscaled.service
```

Enable Bluetooth only if it is needed:

```bash
sudo systemctl enable --now bluetooth.service
```

PipeWire and WirePlumber belong to the user session. Do not create duplicate
system services:

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
```

Docker is optional. Its group grants root-equivalent control over the host:

```bash
sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"
```

Log out and back in after the group change. Tailscale authentication is a
separate step after networking is working:

```bash
sudo tailscale up
tailscale status
```

### Firewall

The kernel's packet filtering support is not an application firewall policy.
This setup uses firewalld with the `public` zone and no unnecessary incoming
services:

```bash
sudo firewall-cmd --set-default-zone=public
firewall-cmd --get-default-zone
firewall-cmd --get-active-zones
firewall-cmd --list-all --zone=public
```

Add an allowed service or port only when that service is intentionally enabled.
For example, do not expose SSH just because `openssh` is installed.

### Portals and Authentication

Install one polkit agent and one portal backend. Noctalia may provide the
selected polkit agent; verify rather than starting a second agent. Hyprland's
portal backend is required for screen sharing and related desktop integrations.

```bash
systemctl --user --type=service | grep -E 'portal|polkit' || true
command -v noctalia
```

If a GTK file chooser or application requires it, add the appropriate GTK
portal backend after testing the generic and Hyprland backends.

## Phase 4: User Configuration

Clone this repository as the normal user and enter its directory:

```bash
mkdir -p ~/src
git clone <repository-url> ~/src/deomarchyfy
cd ~/src/deomarchyfy
```

The repository currently contains these Stow packages:

```text
bash ghostty herdr hyprland tmux
```

Before applying them, inspect and preserve any existing files that would
conflict. GNU Stow intentionally refuses to overwrite unrelated files. Do not
use `stow --adopt` here; it changes the repository from the target machine.

Run the safe preflight first:

```bash
./scripts/stow-configs.sh --dry-run
```

If the output contains no unexpected conflicts, apply the packages:

```bash
./scripts/stow-configs.sh
```

Use `--restow` after changing package contents or removing a managed file:

```bash
./scripts/stow-configs.sh --restow
```

The script manages only user files under `$HOME`. It refuses root execution,
does not use `sudo`, and does not manage Noctalia. Move conflicting files to a
dated backup directory before rerunning the dry run. Keep machine-specific
files such as `/etc/greetd/config.toml` outside Stow.

Validate the links and the applications:

```bash
stow --dir=dotfiles --target="$HOME" --simulate --verbose=1 \
  bash ghostty herdr hyprland tmux
command -v ghostty herdr jj nvim tmux
test -f "$HOME/.config/hypr/hyprland.lua"
```

Neovim is installed and selected as the default editor, but this repository
does not currently provide a Neovim configuration package.

## Phase 5: Direct Hyprland Session

Verify the direct session before enabling greetd:

```bash
command -v Hyprland
command -v hyprctl
test -f /usr/share/wayland-sessions/hyprland.desktop
```

Follow `instructions/hyprland.md` for the direct-session checks. Do not add
UWSM, a second bar, a second notification daemon, or a second launcher.

The current Hyprland configuration starts Noctalia once through its compositor
startup hook. Noctalia must not also be started from Bash, greetd, or a user
service.

### Terminal Working Directory

`SUPER + ENTER` uses
`~/.local/bin/deomarchyfy-launch-terminal` rather than launching Ghostty
directly. When the active window is Ghostty, the launcher uses Ghostty's native
`+new-window` action, which preserves the focused surface's CWD through shell
integration. When another terminal is focused, it walks that terminal's process
tree and uses the first child process whose shell is listed in `/etc/shells`.
It falls back to `$HOME` when no valid shell directory can be found.

Ghostty's `path` shell-integration feature and working-directory inheritance
settings are explicit in its Stow configuration. This preserves the active
Ghostty surface's CWD without a Kitty remote-control socket or UWSM.

## Phase 6: Manual Noctalia and Greeter Setup

Noctalia configuration is intentionally outside the automation. Start it with
defaults, then configure its bar, launcher, notifications, lock, idle behavior,
wallpaper, OSD, control center, and appearance manually.

Install and configure Noctalia Greeter according to
`instructions/greetd-noctalia-greeter.md`. That document covers the pinned
source build, system-owned `/etc/greetd/config.toml`, session discovery, and
safe activation. Do not put Greeter state or machine-specific login settings in
the user Stow packages.

Before enabling greetd:

- Confirm `Ctrl+Alt+F3` reaches a usable TTY.
- Confirm `noctalia-greeter sessions` shows the direct Hyprland session.
- Confirm no other display manager is enabled.
- Keep recovery media available.

Enable greetd only after those checks:

```bash
sudo systemctl enable --now greetd.service
```

Test login, logout, failed authentication, reboot, power actions, and a second
monitor. If the login path fails, use a TTY and inspect:

```bash
sudo journalctl -u greetd -b
sudo systemctl status greetd.service
```

## Phase 7: Identity, Defaults, and Recovery

Configure identity and secrets separately from this repository:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global core.editor nvim
```

Add SSH/GPG keys, credentials, and password-manager integration without
committing secrets or machine-specific tokens. Confirm that backups include
important user data but exclude caches and credentials unless they are
encrypted.

Set default applications only after checking the installed desktop-entry names:

```bash
ls /usr/share/applications
xdg-mime query default inode/directory
xdg-mime query default x-scheme-handler/https
```

For Btrfs, document the selected snapshot tool, schedule, retention policy, and
restore procedure. Test a restore before treating snapshots as backups. Keep a
bootable installer and TTY recovery path available for every login or boot
change.

## Verification Checklist

Run the checks below after the corresponding phase:

```bash
command -v ghostty eos-hwtool herdr jj nvim tmux
systemctl is-enabled NetworkManager.service
systemctl is-active firewalld.service
systemctl is-active power-profiles-daemon.service
firewall-cmd --state
powerprofilesctl get
wpctl status
hyprctl version
hyprctl monitors
```

Then verify behavior, not only command presence:

- A direct Hyprland session starts without UWSM.
- Noctalia starts exactly once and owns its selected shell responsibilities.
- Audio playback and microphone capture work.
- Network, Bluetooth, suspend, display outputs, and clipboard work.
- TTY access remains available.
- Stow links point to this repository and unrelated files were not overwritten.
- A package update and the documented recovery path both work.

## Maintenance

For regular maintenance, update official packages first and inspect Arch news
for changes affecting Hyprland, Noctalia, greetd, graphics, or initramfs:

```bash
sudo pacman -Syu
```

Update AUR packages separately and review their build changes. Re-run the Stow
dry run after repository changes, and use `--restow` only when the package set
or links have intentionally changed.
