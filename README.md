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
scripts/             Safe setup automation
dotfiles/bash/      GNU Stow package for Bash configuration
dotfiles/hyprland/  GNU Stow package for Hyprland configuration
dotfiles/tmux/      GNU Stow package for tmux configuration
dotfiles/herdr/     GNU Stow package for Herdr configuration
dotfiles/ghostty/   GNU Stow package for Ghostty configuration
```

Additional Stow packages will be added only when their configuration is
understood and approved. Noctalia configuration and runtime state are
intentionally managed manually.

## Status

The operating-system, desktop-shell, direct-Hyprland, and login-path decisions
are documented in `OS.md`, `shell.md`, `instructions/hyprland.md`, and
`instructions/greetd-noctalia-greeter.md`. The initial native Lua Hyprland
dotfiles, reviewed keybindings, package inventory, Bash settings, tmux config,
Herdr config, and Ghostty config are present. The end-to-end installation
procedure is in `instructions/installation.md`; `scripts/stow-configs.sh`
applies the current user packages and intentionally excludes Noctalia
configuration. Installation and runtime behavior still need validation on the
target EndeavourOS system.
