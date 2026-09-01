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
dotfiles/starship/  GNU Stow package for Starship configuration
dotfiles/noctalia/  GNU Stow package for reviewed Noctalia configuration
```

Run the numbered scripts in this order:

1. `scripts/01-install-packages.sh` installs official packages.
2. `scripts/02-enable-services.sh` enables the workstation service baseline,
   including Tailscale, Bluetooth, and Docker, and can configure zram and
   explicitly selected services such as SSH.
3. `scripts/03-stow-configs.sh` applies user configuration and handles Bash conflicts;
   use `--replace-bash` for a clean target's stock Bash files. It also safely
   handles the reviewed Starship and Noctalia configuration.
4. `scripts/04-install-noctalia-greeter.sh` builds and installs the pinned Greeter.
5. `scripts/05-configure-greetd.sh` writes and optionally activates `greetd`.
6. `scripts/06-verify-setup.sh` checks the final packages, links, services, session,
   and login path without changing the system.

Additional Stow packages will be added only when their configuration is
understood and approved. The repository manages reviewed handwritten Noctalia
configuration; GUI-managed state, generated files, plugins, and secrets remain
outside Stow.

## Status

The operating-system, desktop-shell, direct-Hyprland, and login-path decisions
are documented in `OS.md`, `shell.md`, `instructions/hyprland.md`, and
`instructions/greetd-noctalia-greeter.md`. The initial native Lua Hyprland
dotfiles, reviewed keybindings, package inventory, Bash settings, tmux config,
Herdr config, Ghostty config, Starship config, and the reviewed Noctalia config
are present. The end-to-end installation
procedure is in `instructions/installation.md`; the numbered scripts install
packages, configure zram and services, apply user packages, and configure the
login path. The final verification script intentionally performs checks only;
it does not change Noctalia configuration or enable greetd. The audited target
has a working direct Hyprland session and an active greetd -> Noctalia Greeter
-> Hyprland login path. Its Omarchy-style Hyprland compositor animations and
separate Noctalia shell animation setting are documented in the relevant
configuration guides.

Run the final check from a terminal inside the graphical session after applying
the selected service options:

```bash
./scripts/06-verify-setup.sh --zram --ssh
```

Use `--pre-greetd` while validating the direct session before the login service
is activated. Optional tools such as `eos-hwtool`, Herdr, and OpenCode are
reported as warnings because they are installed outside the official package
script.
