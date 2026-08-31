# Operating System

## Decision

Use **EndeavourOS** as the base operating system.

EndeavourOS provides an approachable installation experience while staying
close to Arch Linux. This keeps the system aligned with the current Omarchy
environment without retaining Omarchy as a dependency.

## Why EndeavourOS

- The current system is already Arch-based, so the package manager, filesystem
  layout, rolling-release model, and troubleshooting workflow remain familiar.
- Hyprland is a natural fit for the intended desktop and requires less workflow
  translation than moving to a different compositor.
- Noctalia is available for Arch through the official `extra` repository.
- Arch repositories and the AUR provide access to current desktop and developer
  software when the official repositories do not contain a required package.
- The system can remain small because EndeavourOS does not require a complete
  desktop environment for this setup.
- The user retains direct control over systemd, networking, audio, storage,
  services, and package selection.

## What This Replaces

This setup replaces Omarchy's distribution-level defaults and integration. It
does not attempt to reproduce Omarchy wholesale.

- Hyprland will be configured independently.
- Noctalia will provide the desktop shell and its selected services.
- Bash will contain only the useful, portable parts of the current shell setup.
- Dotfiles will be managed through GNU Stow.
- Omarchy-specific launchers, wrappers, paths, generated state, and defaults
  will not be required.

## Tradeoffs

EndeavourOS is not maintenance-free. The rolling-release model requires regular
updates, attention to Arch news, and care when using AUR packages. The setup
must therefore include:

- Regular backups.
- A tested recovery path.
- Btrfs snapshots if the final storage design supports them.
- A preference for official Arch packages before using the AUR.
- Review of package build files and update behavior for third-party software.

Noctalia can simplify the desktop shell, but it does not remove the need to
understand the base system or Hyprland session integration.

## Scope

This decision establishes the operating-system base only. Package selection,
storage layout, login manager, Hyprland configuration, Noctalia configuration,
Bash configuration, and dotfile contents will be decided separately and added
step by step.
