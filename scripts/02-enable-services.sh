#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly USER_HOME="${HOME:?HOME must be set}"

dry_run=false
enable_ssh=false
enable_tailscale=false
enable_bluetooth=false
enable_docker=false
enable_accountsservice=false

usage() {
  printf 'Usage: %s [options]\n' "$SCRIPT_NAME"
  printf '\n'
  printf '%s\n' \
    'Enables the safe core services by default:' \
    '  NetworkManager, firewalld (home zone), power-profiles-daemon, fstrim.timer' \
    '' \
    'Options:' \
    '  --all              Also enable SSH, Tailscale, and Bluetooth' \
    '  --ssh              Enable sshd and allow SSH in firewalld home zone' \
    '  --tailscale        Enable tailscaled (authentication remains separate)' \
    '  --bluetooth        Enable bluetooth.service' \
    '  --docker           Enable Docker and add the user to the docker group' \
    '  --accountsservice  Enable accounts-daemon.service' \
    '  --dry-run          Print actions without changing the system' \
    '  -h, --help         Show this help'
  printf '\n'
  printf 'greetd is intentionally not managed by this script.\n'
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

unit_exists() {
  systemctl cat "$1" >/dev/null 2>&1
}

enable_service() {
  local unit="$1"

  unit_exists "$unit" || die "required service is not installed: $unit"
  run_root systemctl enable --now "$unit"
}

enable_optional_service() {
  local unit="$1"

  if unit_exists "$unit"; then
    enable_service "$unit"
  else
    printf 'warning: optional service is not installed; skipping %s\n' "$unit" >&2
  fi
}

if (( EUID == 0 )); then
  die 'run this script as the target user, not as root'
fi

while (($# > 0)); do
  case "$1" in
    --all)
      enable_ssh=true
      enable_tailscale=true
      enable_bluetooth=true
      ;;
    --ssh)
      enable_ssh=true
      ;;
    --tailscale)
      enable_tailscale=true
      ;;
    --bluetooth)
      enable_bluetooth=true
      ;;
    --docker)
      enable_docker=true
      ;;
    --accountsservice)
      enable_accountsservice=true
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
command -v systemctl >/dev/null 2>&1 || die 'systemd is not available'
command -v firewall-cmd >/dev/null 2>&1 || die 'firewalld is not installed'

if ! $dry_run; then
  sudo -v
fi

enable_service NetworkManager.service
enable_service firewalld.service
enable_service power-profiles-daemon.service
enable_service fstrim.timer

run_root firewall-cmd --set-default-zone=home

if $enable_ssh; then
  [[ -s "$USER_HOME/.ssh/authorized_keys" ]] || die \
    'refusing to enable SSH until ~/.ssh/authorized_keys contains a key'
  enable_service sshd.service
  run_root firewall-cmd --permanent --zone=home --add-service=ssh
  run_root firewall-cmd --reload
fi

if $enable_tailscale; then
  enable_optional_service tailscaled.service
  printf 'Tailscale authentication remains separate: sudo tailscale up\n'
fi

if $enable_bluetooth; then
  enable_optional_service bluetooth.service
fi

if $enable_docker; then
  enable_service docker.service
  run_root usermod -aG docker "$USER"
  printf 'Log out and back in before using Docker without sudo.\n'
fi

if $enable_accountsservice; then
  enable_optional_service accounts-daemon.service
fi

printf 'Core services configured. greetd was not changed.\n'
