#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly CONFIG_FILE="/etc/greetd/config.toml"
readonly GREETER_USER="${GREETD_USER:-greeter}"

dry_run=false
write_config=false
replace_config=false
enable_greetd=false

usage() {
  printf 'Usage: %s [options]\n' "$SCRIPT_NAME"
  printf '\n'
  printf '%s\n' \
    'Validates Noctalia Greeter and prepares the greetd configuration.' \
    '' \
    'Options:' \
    '  --dry-run   Validate prerequisites and print the proposed configuration' \
    '  --write     Write /etc/greetd/config.toml' \
    '  --replace   Back up and replace an existing greetd configuration' \
    '  --enable    Enable and start greetd after writing its configuration' \
    '  -h, --help  Show this help'
  printf '\nThe default action never writes files or starts greetd.\n'
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

if (( EUID == 0 )); then
  die 'run this script as the target user, not as root'
fi

while (($# > 0)); do
  case "$1" in
    --dry-run)
      dry_run=true
      ;;
    --write)
      write_config=true
      ;;
    --replace)
      replace_config=true
      ;;
    --enable)
      enable_greetd=true
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

$replace_config && write_config=true

command -v systemctl >/dev/null 2>&1 || die 'systemd is not available'
command -v noctalia-greeter >/dev/null 2>&1 || die 'noctalia-greeter is not installed'
command -v noctalia-greeter-session >/dev/null 2>&1 || die \
  'noctalia-greeter-session is not installed'

readonly SESSION_COMMAND="$(command -v noctalia-greeter-session)"
readonly GREETER_COMMAND="$(command -v noctalia-greeter)"

[[ -x "$SESSION_COMMAND" ]] || die "Greeter session wrapper is not executable: $SESSION_COMMAND"
[[ -x "$GREETER_COMMAND" ]] || die "Greeter command is not executable: $GREETER_COMMAND"
[[ -f /usr/share/wayland-sessions/hyprland.desktop ]] || die \
  'direct Hyprland session entry is missing'
id "$GREETER_USER" >/dev/null 2>&1 || die "greetd user does not exist: $GREETER_USER"
systemctl cat greetd.service >/dev/null 2>&1 || die 'greetd.service is not installed'

for display_manager in gdm.service sddm.service lightdm.service lxdm.service; do
  if systemctl is-enabled "$display_manager" >/dev/null 2>&1 || \
     systemctl is-active "$display_manager" >/dev/null 2>&1; then
    die "another display manager is enabled or active: $display_manager"
  fi
done

printf -v config_contents \
  '[default_session]\ncommand = "%s"\nuser = "%s"\n' \
  "$SESSION_COMMAND" "$GREETER_USER"

printf 'Greeter command: %s\n' "$GREETER_COMMAND"
printf 'Session wrapper: %s\n' "$SESSION_COMMAND"
printf 'Proposed configuration:\n%s' "$config_contents"

if $dry_run; then
  printf 'No files changed and greetd was not started.\n'
  exit 0
fi

if ! $write_config && ! $enable_greetd; then
  printf 'No files changed and greetd was not started. Use --write after reviewing the configuration.\n'
  exit 0
fi

command -v sudo >/dev/null 2>&1 || die 'sudo is not installed'
sudo -v

if $enable_greetd && ! $write_config; then
  [[ -s "$CONFIG_FILE" ]] || die "missing $CONFIG_FILE; run with --write first"
  printf 'Enabling greetd now; run this option from a recovery-ready TTY.\n'
  sudo systemctl enable --now greetd.service
  printf 'greetd enabled.\n'
  exit 0
fi

if [[ -e "$CONFIG_FILE" && ! $replace_config ]]; then
  die "$CONFIG_FILE already exists; use --replace only after reviewing it"
fi

temporary_config="$(mktemp)"
trap 'rm -f "$temporary_config"' EXIT
printf '%s' "$config_contents" >"$temporary_config"

if [[ -e "$CONFIG_FILE" ]]; then
  backup_file="${CONFIG_FILE}.before-deomarchyfy.$(date +%Y%m%d-%H%M%S)"
  sudo cp -- "$CONFIG_FILE" "$backup_file"
  printf 'Backed up existing configuration to %s\n' "$backup_file"
fi

sudo install -d -m 0755 /etc/greetd
sudo install -o root -g root -m 0644 "$temporary_config" "$CONFIG_FILE"
printf 'Wrote %s\n' "$CONFIG_FILE"

if $enable_greetd; then
  printf 'Enabling greetd now; run this option from a recovery-ready TTY.\n'
  sudo systemctl enable --now greetd.service
else
  printf 'greetd was not enabled. Review the configuration before using --enable.\n'
fi
