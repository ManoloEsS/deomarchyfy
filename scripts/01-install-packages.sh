#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"

dry_run=false
skip_upgrade=false

readonly -a official_packages=(
  base-devel bluez bluez-utils ca-certificates curl dbus dracut firewalld
  bash-completion bat docker eza firefox fzf git glances ghostty greetd
  hyprland inotify-tools jujutsu mise neovim networkmanager noctalia tailscale
  less nautilus openssh pipewire pipewire-alsa pipewire-jack pipewire-pulse
  polkit power-profiles-daemon python-gobject rsync starship stow tmux upower
  wireplumber ttf-jetbrains-mono-nerd xdg-desktop-portal
  xdg-desktop-portal-hyprland xdg-utils zram-generator zoxide
)

usage() {
  printf 'Usage: %s [options]\n' "$SCRIPT_NAME"
  printf '\n'
  printf '%s\n' \
    'Installs the official repository package inventory.' \
    'AUR and upstream applications are intentionally excluded.' \
    '' \
    'Options:' \
    '  --no-upgrade  Skip the initial full system upgrade' \
    '  --dry-run     Print planned actions without changing the system' \
    '  -h, --help    Show this help'
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

run_root() {
  if $dry_run; then
    printf '+ sudo'
    printf ' %q' "$@"
    printf '\n'
  else
    sudo "$@"
  fi
}

if (( EUID == 0 )); then
  die 'run this script as the target user, not as root'
fi

while (($# > 0)); do
  case "$1" in
    --no-upgrade)
      skip_upgrade=true
      ;;
    --dry-run)
      dry_run=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

command -v sudo >/dev/null 2>&1 || die 'sudo is not installed'
command -v pacman >/dev/null 2>&1 || die 'pacman is not installed'

if ! $dry_run; then
  sudo -v
fi

if ! $skip_upgrade; then
  run_root pacman -Syu
fi

run_root pacman -S --needed "${official_packages[@]}"
printf 'Official package installation complete.\n'
printf 'AUR and upstream applications were not installed.\n'
