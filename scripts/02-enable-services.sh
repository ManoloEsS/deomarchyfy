#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly USER_HOME="${HOME:?HOME must be set}"
readonly ZRAM_CONFIG_FILE='/etc/systemd/zram-generator.conf'
readonly ZRAM_CONFIG_CONTENT='[zram0]
zram-size = ram
compression-algorithm = zstd
'

dry_run=false
enable_ssh=false
enable_tailscale=true
enable_bluetooth=true
enable_docker=true
enable_accountsservice=false
configure_zram=false
ssh_key_file=''

usage() {
  printf 'Usage: %s [options]\n' "$SCRIPT_NAME"
  printf '\n'
  printf '%s\n' \
    'Enables the workstation core services by default:' \
    '  NetworkManager, firewalld (home zone), power-profiles-daemon, fstrim.timer' \
    '  Tailscale daemon, Bluetooth, Docker (and the user docker group)' \
    '' \
    'Options:' \
    '  --all              Also enable SSH and AccountsService' \
    '  --ssh              Enable sshd and allow SSH in firewalld home zone' \
    '  --ssh-key-file PATH  Install a public key before enabling SSH' \
    '  --zram             Configure zram-generator for non-hibernating swap' \
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

validate_ssh_key_file() {
  local candidate

  [[ -f "$ssh_key_file" ]] || die "SSH public-key file not found: $ssh_key_file"
  command -v ssh-keygen >/dev/null 2>&1 || die 'ssh-keygen is not installed'

  ssh_key_line=""
  while IFS= read -r candidate; do
    [[ -n "$candidate" && "$candidate" != \#* ]] || continue
    ssh_key_line="$candidate"
    break
  done <"$ssh_key_file"
  [[ -n "$ssh_key_line" ]] || die "SSH public-key file is empty: $ssh_key_file"
  [[ "$ssh_key_line" =~ ^(ssh-ed25519|ssh-rsa|ecdsa-sha2-|sk-ssh-|sk-ecdsa-)[[:space:]] ]] || die \
    "not an SSH public-key line: $ssh_key_file"
  ssh-keygen -lf "$ssh_key_file" >/dev/null 2>&1 || die \
    "not a valid SSH public-key file: $ssh_key_file"
}

if (( EUID == 0 )); then
  die 'run this script as the target user, not as root'
fi

while (($# > 0)); do
  case "$1" in
    --all)
      enable_ssh=true
      enable_accountsservice=true
      ;;
    --ssh)
      enable_ssh=true
      ;;
    --ssh-key-file)
      (($# > 1)) || die '--ssh-key-file requires a path'
      ssh_key_file="$2"
      enable_ssh=true
      shift
      ;;
    --zram)
      configure_zram=true
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

if [[ -n "$ssh_key_file" ]]; then
  validate_ssh_key_file
elif $enable_ssh && ! $dry_run; then
  [[ -s "$USER_HOME/.ssh/authorized_keys" ]] || die \
    'refusing to enable SSH until ~/.ssh/authorized_keys contains a key'
fi

if $configure_zram; then
  command -v pacman >/dev/null 2>&1 || die 'pacman is not installed'
  pacman -Q zram-generator >/dev/null 2>&1 || die \
    'zram-generator is not installed; run scripts/01-install-packages.sh first'
  if [[ -e "$ZRAM_CONFIG_FILE" ]]; then
    cmp -s "$ZRAM_CONFIG_FILE" <(printf '%s' "$ZRAM_CONFIG_CONTENT") || die \
      "$ZRAM_CONFIG_FILE already exists with different contents; review it before replacing"
  fi
fi

if ! $dry_run; then
  sudo -v
fi

enable_service NetworkManager.service
enable_service firewalld.service
enable_service power-profiles-daemon.service
enable_service fstrim.timer

run_root firewall-cmd --set-default-zone=home

if $configure_zram; then
  if [[ -e "$ZRAM_CONFIG_FILE" ]]; then
    printf '%s already matches the selected zram configuration.\n' "$ZRAM_CONFIG_FILE"
  elif $dry_run; then
    printf '+ install zram configuration at %s\n' "$ZRAM_CONFIG_FILE"
  else
    temporary_config="$(mktemp)"
    printf '%s' "$ZRAM_CONFIG_CONTENT" >"$temporary_config"
    run_root install -o root -g root -m 0644 "$temporary_config" "$ZRAM_CONFIG_FILE"
    rm -- "$temporary_config"
    printf 'Wrote %s; reboot to activate generated zram swap.\n' "$ZRAM_CONFIG_FILE"
  fi
fi

if $enable_ssh; then
  if [[ -n "$ssh_key_file" ]]; then
    authorized_keys="$USER_HOME/.ssh/authorized_keys"
    if $dry_run; then
      printf '+ install public key into %s\n' "$authorized_keys"
    else
      install -d -m 0700 "$USER_HOME/.ssh"
      touch "$authorized_keys"
      chmod 0600 "$authorized_keys"
      if ! grep -Fqx -- "$ssh_key_line" "$authorized_keys"; then
        printf '%s\n' "$ssh_key_line" >>"$authorized_keys"
      fi
    fi
  fi

  if ! $dry_run || [[ -z "$ssh_key_file" ]]; then
    [[ -s "$USER_HOME/.ssh/authorized_keys" ]] || die \
      'refusing to enable SSH until ~/.ssh/authorized_keys contains a key'
  fi
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
