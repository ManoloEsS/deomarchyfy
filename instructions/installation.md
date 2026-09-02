# EndeavourOS Installation and Setup

## Scope

This is the end-to-end procedure for a clean EndeavourOS installation. It
separates work performed by the EndeavourOS installer, normal post-install
administration, and this repository's user configuration.

The repository manages reviewed handwritten Noctalia configuration through GNU
Stow. GUI-managed Noctalia state, generated files, plugins, encrypted storage,
and Greeter state remain outside Stow.

The intended session path is:

```text
greetd -> Noctalia Greeter -> direct Hyprland session -> Noctalia Shell
```

Read `OS.md`, `packages.md`, `instructions/hyprland.md`, and
`instructions/greetd-noctalia-greeter.md` before changing the target system.
Use `instructions/noctalia-runtime.md` for the manual desktop runtime
installation and behavior checks.

## Phase 1: Installer Decisions

Use the current EndeavourOS installer and recheck its options before confirming
the installation. Installer labels and defaults can change.

### Firmware and Disk

- Boot the installer in UEFI mode. Confirm this from the firmware menu rather
  than assuming the boot mode.
- Use GPT for a UEFI installation.
- Disable Secure Boot unless you have a separately tested signing setup.
- Disable CSM/legacy boot when possible.
- The current Calamares configuration defaults to ext4 and systemd-boot. For
  this project, select **Btrfs** because snapshots and rollback are part of the
  intended recovery design. Use the installer's Btrfs subvolume layout and
  record it before confirming the installation.
- Btrfs snapshots are not automatically backups. Choose and document a snapshot
  tool, schedule, retention policy, and restore procedure after the first boot.
- Encryption generation is installer-release dependent. Verify the LUKS
  generation shown by the installer before accepting it rather than assuming
  LUKS1 or LUKS2. The audited target currently uses LUKS2. Use a manual,
  separately documented procedure if a specific generation is a hard
  requirement.
- Do not create a separate `/home` filesystem merely by habit. With Btrfs,
  choose subvolumes deliberately so root rollback does not unexpectedly include
  or exclude user data.
- Use zram for normal swap if hibernation is not required. Hibernation needs a
  real swap area or correctly configured swapfile, sufficient capacity, and
  resume configuration in the initramfs and kernel command line.
- Keep the EFI System Partition outside the encrypted container and do not
  format an existing EFI partition without confirming that it is safe.
- Current installer guidance recommends a 2 GiB EFI partition for systemd-boot
  and accepts 500 MiB as the minimum. GRUB uses a smaller `/boot/efi` layout.

### Bootloader

- Prefer systemd-boot for a straightforward single-OS UEFI machine. It is the
  current installer default.
- Prefer GRUB when multi-boot detection, legacy firmware support, or a more
  flexible boot menu is required.
- Record the selected bootloader and disk layout. Future recovery instructions
  depend on this choice.

### Installer Profile

- Use **Online installation**. EndeavourOS documents Offline installation as a
  fallback; it installs ISO-time packages and currently offers only KDE/Plasma.
- For this project's minimal target, choose **No Desktop**. The system will boot
  to text mode after installation, and we install Hyprland and Noctalia in the
  controlled post-install phase.
- Do not select GNOME, KDE, Xfce, Cinnamon, COSMIC, Budgie, LXQt, or Sway-WM for
  the minimal target. Selecting GNOME installs a complete desktop and GDM; it is
  not just a hardware or GTK compatibility layer.
- Create the normal user account during installation and use it for Stow and
  AUR work. Do not use root for user configuration.
- Enable networking in the installer if needed, but treat it as a first-boot
  dependency check rather than proof that the final service configuration is
  correct.
- Let the installer install its normal kernel, firmware, microcode, initramfs,
  and package-manager baseline. Do not duplicate those blindly in the first
  package command.

After reboot, confirm that the system boots from the intended disk and that the
normal user can reach a TTY. With **No Desktop**, no display manager should be
running yet. If GNOME was selected as a fallback, expect GDM to be installed;
disable it before enabling the repository's greetd path.

## EndeavourOS Installer Selections

The following recommendations are based on the current official online
installer sources. The `main` branch of the ISO repository is development
state, so verify labels and default states in the exact ISO being used.

### Final Non-Package Choices

| Installer item | Final choice | Notes |
| --- | --- | --- |
| Installation method | **Online** | Provides current packages and the full selection screen |
| Desktop environment | **No Desktop** | Hyprland and Noctalia are installed after the first boot |
| Filesystem | **Btrfs** | Use the installer's subvolume layout and record it |
| Encrypt system | **Checked** | Encrypt the system/root volume; leave the EFI System Partition unencrypted |
| Bootloader | **systemd-boot** | UEFI + GPT, single EndeavourOS installation |
| Swap | **None** | Use zram later; add disk swap only if hibernation becomes a requirement |
| Automatic login | **Disabled** | Require the normal user password at Noctalia Greeter |

The resulting boot flow is intentionally:

```text
disk-encryption password -> Noctalia Greeter -> user password -> Hyprland
```

The encryption password unlocks the disk; it does not authenticate the user.
Keep the two passwords separate. Do not configure TPM auto-unlock or display
manager autologin initially. Omarchy's single-password startup is achieved by
SDDM autologin after disk unlock; that is a convenience choice and is not the
login behavior selected for this system.

### Recommended for This Project

| Installer item | Selection | Reason |
| --- | --- | --- |
| Installation method | **Online** | Current packages, all desktop choices, and package deselection |
| Desktop | **No Desktop** | Avoids a competing desktop and display manager |
| Desktop-Base + Common packages | **Checked** | Keeps the required base integration |
| X11 subgroup | **Unchecked** | This is a Wayland-first setup; add `xorg-xwayland` later if needed |
| Network | **Checked** | NetworkManager, OpenSSH, Wi-Fi support, and networking tools |
| Package management | **Checked** | `yay` and useful Arch maintenance tools |
| Desktop integration | **Checked** | D-Bus, Bluetooth packages, media codecs, `xdg-utils`, and user directories |
| Filesystem | **Checked** | Firmware/EFI and common filesystem utilities |
| Fonts | **Checked** | Basic font coverage for desktop applications |
| Audio | **Checked** | PipeWire, WirePlumber, ALSA, and audio support |
| Hardware | **Checked** | Hardware detection, firmware-related tools, and diagnostics |
| Power | **Checked** | `power-profiles-daemon` and UPower |
| EndeavourOS applications | **Checked** | Keep EOS logging, package inventory, and mirror-management tools |
| Recommended applications | **Checked** | Git, rsync, glances, hardware information, and useful maintenance tools |
| Firefox and language package | **Checked** | Firefox is part of the selected workstation inventory |
| Spell Checker and language package | **Unchecked** | Not required by the planned minimal setup |
| Firewall | **Checked** | Installs and enables Firewalld |
| LTS kernel in addition | **Unchecked** | Add only for a known hardware or regression reason |
| Printing support | **Unchecked** | No printer requirement has been selected |
| HP printer/scanner support | **Unchecked** | No HP device requirement has been selected |

If individual packages can be deselected inside **EndeavourOS applications**, the
selected tools to retain are `eos-log-tool`, `eos-packagelist`, `eos-rankmirrors`,
and `reflector-simple`. `endeavouros-branding`, `eos-apps-info`, `eos-quickstart`,
and `welcome` are optional cosmetic or onboarding items.

Keep `xdg-utils` and `xdg-user-dirs` from Desktop integration. Install and keep
`xdg-desktop-portal` and `xdg-desktop-portal-hyprland` in the post-install package
phase. These XDG packages are required desktop integration and are unrelated to
the optional X11 subgroup.

`nautilus` is also installed in the post-install package phase. It does not
require selecting the GNOME desktop, GNOME Shell, or GDM.

Keep the common subgroups checked unless there is a specific reason to remove
their individual packages. The installer groups contain some optional tools, but
removing an entire subgroup can remove dependencies needed for networking,
audio, portals, hardware, or power management.

### If GNOME Is Required as a Fallback

If "use GNOME" means keeping a complete GNOME session available in addition to
Hyprland, select **GNOME** instead of **No Desktop**. This is a valid but less
minimal choice. The GNOME profile currently installs:

```text
adwaita-icon-theme loupe evince file-roller gdm
gnome-calculator gnome-clocks gnome-console gnome-control-center
gnome-disk-utility gnome-keyring gnome-nettool gnome-power-manager
gnome-shell gnome-system-monitor gnome-terminal gnome-text-editor
gnome-themes-extra gnome-tweaks gnome-usage gnome-weather
gvfs gvfs-afc gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb
nautilus sushi showtime xdg-desktop-portal-gnome
xdg-desktop-portal xdg-user-dirs-gtk
```

For that option:

- Keep the GNOME desktop package group selected.
- Uncheck the GNOME **EndeavourOS settings** subgroup for vanilla GNOME. It
  contains `arc-gtk-theme-eos`, `eos-settings-gnome`, and `eos-qogir-icons`.
- Do not select another desktop environment or Sway-WM.
- Expect `gdm.service` to be enabled by the GNOME installation.
- Before enabling our `greetd` path, disable GDM and confirm that only one login
  manager owns the graphical target:

  ```bash
  sudo systemctl disable --now gdm.service
  ```

- Keep the GNOME portal initially only if GNOME applications need it. Test
  portal selection before adding another portal backend.

GNOME does not replace Hyprland or Noctalia, but installing it adds a second
desktop shell, display manager, application set, and portal backend. It should
be treated as an intentional fallback, not as a minimal base.

### Installer Defaults That Need Post-Install Attention

The current EndeavourOS service configuration attempts to enable installed units
including NetworkManager, Firewalld, power profiles, `fstrim.timer`, and the
selected desktop's display manager. It explicitly disables Bluetooth by default.
The installer package list includes `openssh`, but it does not enable
`sshd.service`; this repository enables SSH separately after key setup.

Do not confuse the live ISO package list with the installed profile. The current
live ISO itself is KDE-based; the online GNOME package list is separate.

### Official Research Sources

- [EndeavourOS live ISO installation guidance](https://discovery.endeavouros.com/installation/live-iso-tricks-tips/2021/03/)
- [EndeavourOS installer customization](https://discovery.endeavouros.com/installation/customizing-the-endeavouros-install-process/2022/03/)
- [Current desktop chooser](https://raw.githubusercontent.com/endeavouros-team/calamares/calamares/data/eos/modules/packagechooser.conf)
- [Current online package groups](https://raw.githubusercontent.com/endeavouros-team/calamares/calamares/data/eos/modules/netinstall.yaml)
- [Current service handling](https://raw.githubusercontent.com/endeavouros-team/calamares/calamares/data/eos/modules/services-systemd.conf)
- [Current display-manager handling](https://raw.githubusercontent.com/endeavouros-team/calamares/calamares/data/eos/modules/displaymanager.conf)
- [Current partition defaults](https://raw.githubusercontent.com/endeavouros-team/calamares/calamares/data/eos/modules/partition.conf)
- [Official GNOME notes](https://discovery.endeavouros.com/desktop-environments/gnome-desktop/2024/09/)

## Phase 2: First Boot Baseline

Run these commands from a TTY or an existing graphical terminal on the new
system. Review the transaction before accepting it.

```bash
sudo pacman -Syu
sudo pacman -S --needed git
mkdir -p ~/src
git clone <repository-url> ~/src/deomarchyfy
cd ~/src/deomarchyfy
./scripts/01-install-packages.sh --no-upgrade
```

`01-install-packages.sh` uses `--needed`, so packages already provided by the
selected EndeavourOS profile are not reinstalled. Recheck package names before
running it because Arch repositories and profiles change.

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

### zram

The installer choice was no disk swap. Configure one compressed RAM swap device
with the service script. It installs the generator configuration only when it is
missing or already matches the reviewed contents; a different existing
configuration is left untouched and reported for review:

```bash
./scripts/02-enable-services.sh --zram
```

This invocation also applies the core service baseline described below, so do
not repeat the no-option service command when following this path.

The zram units are generated during boot. Reboot after the script completes
rather than trying to enable the generated setup service permanently:

```bash
sudo reboot
```

After logging back in, verify the device:

```bash
swapon --show
zramctl
```

### Services

The repository was cloned during Phase 2. Run the numbered service script rather
than maintaining a second list of `systemctl` commands. If zram was not
configured with the command above, its default action enables the workstation
core services, including Tailscale's daemon, Bluetooth, Docker, and the user's
`docker` group, and sets the Firewalld default zone to `home`:

```bash
./scripts/02-enable-services.sh
```

The script does not enable `greetd`. SSH and AccountsService remain explicit
options:

```bash
./scripts/02-enable-services.sh --ssh
./scripts/02-enable-services.sh --accountsservice
```

The `--ssh` option refuses to start `sshd` until the user's
`~/.ssh/authorized_keys` contains a key and then adds SSH to the Firewalld
`home` zone. Use the following to install one supplied public key idempotently
before enabling SSH; the option also implies `--ssh`:

```bash
./scripts/02-enable-services.sh --ssh-key-file /path/to/client.pub
```

Tailscale authentication remains a separate `sudo tailscale up` step because it
requires the user's tailnet identity. Docker adds the user to a root-equivalent
group and requires a new login.

PipeWire and WirePlumber belong to the user session. The `pipewire-pulse.service`
process may be inactive until its socket is used. Do not create duplicate system
services; verify the sockets and an actual audio client instead:

```bash
systemctl --user is-active pipewire wireplumber pipewire-pulse.socket
wpctl status
```

Tailscale authentication is a separate step after networking is working:

```bash
sudo tailscale up
tailscale status
```

### Firewall

The kernel's packet filtering support is not an application firewall policy.
This setup uses firewalld with the `home` zone because the machine will remain
on a trusted home network. Services are still allow-listed rather than opened
automatically:

```bash
firewall-cmd --get-default-zone
firewall-cmd --get-active-zones
firewall-cmd --list-all --zone=home
```

SSH is intentionally enabled in this setup. Before enabling remote access,
install the user's public key in `~/.ssh/authorized_keys`, then run the service
script with `--ssh`:

```bash
./scripts/02-enable-services.sh --ssh
firewall-cmd --list-services --zone=home
```

If SSH is not needed on a particular machine, skip `sshd.service` and do not
add the firewall service. Do not expose any other incoming service merely
because its package is installed.

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

The repository was cloned during Phase 2. Enter its directory as the normal user:

```bash
cd ~/src/deomarchyfy
```

The repository currently contains these Stow packages:

```text
bash ghostty herdr hyprland noctalia starship tmux
```

Before applying them, inspect and preserve any existing files that would
conflict. The numbered Stow script handles Bash specially: identical default
files are backed up automatically, customized Bash files are preserved and the
Bash package is skipped, and unrelated conflicts still stop the run. On a clean
target with only stock Bash skeletons, use `--replace-bash` to back them up and
apply the repository Bash package. Do not use `stow --adopt` here; it changes the
repository from the target machine.

Run the safe preflight first:

```bash
./scripts/03-stow-configs.sh --dry-run
```

If the output contains no unexpected conflicts, apply the packages:

```bash
./scripts/03-stow-configs.sh --replace-bash
```

Use `--restow` after changing package contents or removing a managed file:

```bash
./scripts/03-stow-configs.sh --restow
```

The script manages only user files under `$HOME`. It refuses root execution,
does not use `sudo`, and does not fold whole directories into repository
symlinks. Existing Bash, Starship, and Noctalia files are handled safely:
identical files are backed up automatically, customized files are preserved and
that package is skipped, and explicit `--replace-bash`, `--replace-starship`, or
`--replace-noctalia` options are required to replace customized files. If an
older run folded `.local` into the repository, the script moves runtime `share`
and `state` data back under `$HOME` before restowing. Unrelated conflicts still
stop the run. Keep machine-specific files such as `/etc/greetd/config.toml` and
Noctalia's GUI-managed state outside Stow.

Validate the links and the applications:

```bash
./scripts/03-stow-configs.sh --dry-run
command -v ghostty herdr jj nvim starship tmux
test -f "$HOME/.config/hypr/hyprland.lua"
test -f "$HOME/.config/noctalia/config.toml"
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

Validate the Noctalia launcher from a terminal before relying on its keybinding:

```bash
noctalia msg panel-toggle launcher
```

`SUPER + SPACE` uses the same Noctalia v5 `panel-toggle launcher` action.

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

The reviewed handwritten Noctalia configuration is applied by the Stow package.
Start Noctalia with that configuration, then configure its bar, launcher,
notifications, wallpaper, OSD, control center, and appearance manually.
Noctalia provides active-session locking and idle behavior through the reviewed
`[lockscreen]`, `[idle.behavior.lock]`, and `[idle.behavior.screen-off]` settings.
GUI-managed overrides remain in
`~/.local/state/noctalia/settings.toml` and are not part of the repository.
Because that state loads after the Stow-managed file, confirm in Noctalia's
settings that its lock screen and lock/screen-off idle behaviors are enabled
after the first start.

Follow `instructions/noctalia-runtime.md` before relying on the keybindings. It
contains the package, effective-configuration, IPC, lock, idle, wake, suspend,
and recovery checks. Do not skip the effective configuration check: GUI-managed
Noctalia state can override the Stow file.

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
./scripts/05-configure-greetd.sh --enable
```

Test login, logout, failed authentication, reboot, power actions, and a second
monitor. If the login path fails, use a TTY and inspect:

```bash
sudo journalctl -u greetd -b
sudo systemctl status greetd.service
```

From the first successful graphical login, run the repository's read-only final
verification. It checks the managed links, required commands, selected services,
Hyprland configuration, Noctalia configuration including effective lock/idle
ownership, and greetd session discovery:

```bash
./scripts/06-verify-setup.sh
```

Pass `--zram`, `--ssh`, and `--accountsservice` for options selected during
installation. Use `--pre-greetd` if validating the direct session before the
login service is enabled. The script never uses `sudo` and never changes files,
services, or Noctalia state.

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
command -v ghostty jj nvim tmux
command -v eos-hwtool || true
command -v herdr || true
command -v opencode || true
systemctl is-enabled NetworkManager.service
systemctl is-active firewalld.service
systemctl is-active power-profiles-daemon.service
systemctl is-enabled sshd.service
firewall-cmd --state
powerprofilesctl get
wpctl status
hyprctl version
hyprctl monitors
```

Then verify behavior, not only command presence:

- A direct Hyprland session starts without UWSM.
- Noctalia starts exactly once and owns its selected shell responsibilities.
- Noctalia's lock screen can authenticate, and idle lock and monitor wake work
  without a second lock or idle daemon.
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
