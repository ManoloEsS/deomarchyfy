# deomarchyfy

A step-by-step setup for a minimal EndeavourOS workstation using Hyprland,
Noctalia, and a focused Bash environment.

## Goals

- Start from a clean EndeavourOS installation.
- Install and configure Hyprland and Noctalia deliberately.
- Keep only the useful parts of the current Omarchy workflow.
- Manage portable configuration with GNU Stow.
- Review each setup step before adding more files or customization.

## Layout

```text
OS.md               Operating-system decision and boundaries
shell.md            Noctalia shell decision and responsibilities
packages.md         Baseline and personal package inventory
instructions/       Installation and configuration steps
scripts/             Safe setup, package, and service automation
dotfiles/bash/      GNU Stow package for Bash configuration
dotfiles/hyprland/  GNU Stow package for Hyprland configuration
dotfiles/tmux/      GNU Stow package for tmux configuration
dotfiles/herdr/     GNU Stow package for Herdr configuration
dotfiles/ghostty/   GNU Stow package for Ghostty configuration
```

Run the numbered scripts in this order:

1. `scripts/01-install-packages.sh` installs official packages.
2. `scripts/02-enable-services.sh` enables the safe system-service baseline.
3. `scripts/03-stow-configs.sh` applies user configuration and handles Bash conflicts.
4. `scripts/04-install-noctalia-greeter.sh` builds and installs the pinned Greeter.
5. `scripts/05-configure-greetd.sh` writes and optionally activates `greetd`.

Additional Stow packages will be added only when their configuration is
understood and approved. Noctalia configuration and runtime state are
intentionally managed manually.

## Status

The operating-system, desktop-shell, direct-Hyprland, and login-path decisions
are documented in `OS.md`, `shell.md`, `instructions/hyprland.md`, and
`instructions/greetd-noctalia-greeter.md`. The initial native Lua Hyprland
dotfiles, reviewed keybindings, package inventory, Bash settings, tmux config,
Herdr config, and Ghostty config are present. The end-to-end installation
procedure is in `instructions/installation.md`; the numbered scripts install
packages, manage services, apply user packages, and configure the login path.
They intentionally exclude Noctalia configuration and automatic greetd
activation. Installation and runtime behavior still need validation on the
target EndeavourOS system.
