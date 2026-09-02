#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TARGET="${HOME:?HOME must be set}"

require_zram=false
require_ssh=false
require_accountsservice=false
require_login=true
failures=0
warnings=0

usage() {
  printf 'Usage: %s [options]\n' "$SCRIPT_NAME"
  printf '\n'
  printf '%s\n' \
    'Verifies the installed workstation without changing files or services.' \
    '' \
    'Options:' \
    '  --zram             Require active /dev/zram0 swap' \
    '  --ssh              Require sshd and the firewalld SSH rule' \
    '  --accountsservice  Require accounts-daemon.service' \
    '  --pre-greetd       Skip greetd and Noctalia Greeter checks' \
    '  -h, --help         Show this help'
}

pass() {
  printf 'PASS  %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'WARN  %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL  %s\n' "$1"
}

check_command() {
  local command_name="$1"

  if command -v "$command_name" >/dev/null 2>&1; then
    pass "command available: $command_name"
  else
    fail "command missing: $command_name"
  fi
}

check_optional_command() {
  local command_name="$1"

  if command -v "$command_name" >/dev/null 2>&1; then
    pass "optional command available: $command_name"
  else
    warn "optional command is not installed: $command_name"
  fi
}

check_link() {
  local target="$1"
  local source="$2"

  if [[ -L "$target" ]] && [[ "$(readlink -f -- "$target")" == "$(readlink -f -- "$source")" ]]; then
    pass "Stow link: $target"
  else
    fail "Stow link does not point to the repository: $target"
  fi
}

check_service() {
  local unit="$1"

  if systemctl is-enabled "$unit" >/dev/null 2>&1; then
    pass "enabled: $unit"
  else
    fail "not enabled: $unit"
  fi

  if systemctl is-active "$unit" >/dev/null 2>&1; then
    pass "active: $unit"
  else
    fail "not active: $unit"
  fi
}

check_firewalld_zone() {
  local zone

  if zone="$(firewall-cmd --get-default-zone 2>/dev/null)" && [[ "$zone" == 'home' ]]; then
    pass 'firewalld default zone is home'
  else
    fail 'firewalld default zone is not home'
  fi
}

check_hyprland_runtime() {
  local output
  local noctalia_count

  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" || -z "${WAYLAND_DISPLAY:-}" ]]; then
    fail 'run this verification from inside the active Hyprland session'
    return
  fi

  if hyprctl version >/dev/null 2>&1; then
    pass 'Hyprland compositor responds to hyprctl'
  else
    fail 'Hyprland compositor did not respond to hyprctl'
  fi

  if output="$(hyprctl configerrors 2>&1)"; then
    pass "Hyprland configuration check completed: ${output//$'\n'/ }"
  else
    printf '%s\n' "$output" >&2
    fail 'Hyprland reported configuration errors'
  fi

  if ! command -v pgrep >/dev/null 2>&1; then
    fail 'pgrep is required to verify the Noctalia process count'
  else
    noctalia_count="$(pgrep -u "$(id -u)" -x noctalia 2>/dev/null | wc -l || true)"
    if (( noctalia_count == 1 )); then
      pass 'Noctalia is running exactly once'
    elif (( noctalia_count == 0 )); then
      fail 'Noctalia is not running'
    else
      fail "Noctalia is running more than once ($noctalia_count processes)"
    fi
  fi
}

check_noctalia_lock_idle_settings() {
  local exported

  if ! command -v python3 >/dev/null 2>&1; then
    fail 'python3 is required to inspect Noctalia effective settings'
    return
  fi

  if ! exported="$(noctalia config export merged 2>&1)"; then
    printf '%s\n' "$exported" >&2
    fail 'could not export the effective Noctalia configuration'
    return
  fi

  if python3 -c '
import sys
import tomllib

config = tomllib.loads(sys.stdin.read())
paths = (
    ("lockscreen", "enabled"),
    ("idle", "behavior", "lock", "enabled"),
    ("idle", "behavior", "screen-off", "enabled"),
)
disabled = []
for path in paths:
    value = config
    for part in path:
        if not isinstance(value, dict) or part not in value:
            value = None
            break
        value = value[part]
    if value is not True:
        disabled.append(".".join(path))

if disabled:
    print("disabled or missing settings: " + ", ".join(disabled), file=sys.stderr)
    raise SystemExit(1)
' <<<"$exported"; then
    pass 'Noctalia lock screen and lock/screen-off idle behaviors are enabled'
  else
    fail 'Noctalia effective configuration does not enable the lock and idle behaviors'
  fi
}

check_greeter_path() {
  local config_file='/etc/greetd/config.toml'
  local session_command
  local sessions

  check_service greetd.service

  if [[ -f "$config_file" ]]; then
    pass "greetd configuration exists: $config_file"
  else
    fail "greetd configuration is missing: $config_file"
    return
  fi

  if ! session_command="$(command -v noctalia-greeter-session)"; then
    fail 'cannot resolve the Noctalia Greeter session wrapper'
    return
  fi
  if grep -Fqx "command = \"$session_command\"" "$config_file"; then
    pass 'greetd uses the installed Noctalia Greeter session wrapper'
  else
    fail 'greetd does not use the installed Noctalia Greeter session wrapper'
  fi

  if grep -Fqx 'vt = 1' "$config_file"; then
    pass 'greetd targets VT 1'
  else
    fail 'greetd does not explicitly target VT 1'
  fi

  if sessions="$(noctalia-greeter sessions 2>&1)" && grep -Fxq 'Hyprland' <<<"$sessions"; then
    pass 'Noctalia Greeter discovers a Hyprland session'
  else
    printf '%s\n' "$sessions" >&2
    fail 'Noctalia Greeter did not report a Hyprland session'
  fi
}

while (($# > 0)); do
  case "$1" in
    --zram)
      require_zram=true
      ;;
    --ssh)
      require_ssh=true
      ;;
    --accountsservice)
      require_accountsservice=true
      ;;
    --pre-greetd)
      require_login=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

if (( EUID == 0 )); then
  printf 'error: run this script as the target user, not as root\n' >&2
  exit 1
fi

command -v systemctl >/dev/null 2>&1 || {
  printf 'error: systemd is not available\n' >&2
  exit 1
}

printf 'Verifying deomarchyfy setup at %s\n\n' "$ROOT"

for command_name in \
  Hyprland hyprctl noctalia starship ghostty jj nvim tmux stow tailscale bluetoothctl docker \
  firewall-cmd powerprofilesctl; do
  check_command "$command_name"
done

if $require_login; then
  check_command noctalia-greeter
  check_command noctalia-greeter-session
fi

for command_name in eos-hwtool herdr opencode; do
  check_optional_command "$command_name"
done

printf '\nChecking managed user configuration\n'
check_link "$TARGET/.bashrc" "$ROOT/dotfiles/bash/.bashrc"
check_link "$TARGET/.bash_profile" "$ROOT/dotfiles/bash/.bash_profile"
check_link "$TARGET/.profile" "$ROOT/dotfiles/bash/.profile"
check_link "$TARGET/.bash_aliases" "$ROOT/dotfiles/bash/.bash_aliases"
check_link "$TARGET/.bash_functions" "$ROOT/dotfiles/bash/.bash_functions"
check_link "$TARGET/.inputrc" "$ROOT/dotfiles/bash/.inputrc"
check_link "$TARGET/.config/ghostty/config" "$ROOT/dotfiles/ghostty/.config/ghostty/config"
check_link "$TARGET/.config/herdr/config.toml" "$ROOT/dotfiles/herdr/.config/herdr/config.toml"
check_link "$TARGET/.config/hypr/hyprland.lua" "$ROOT/dotfiles/hyprland/.config/hypr/hyprland.lua"
check_link "$TARGET/.config/noctalia/config.toml" "$ROOT/dotfiles/noctalia/.config/noctalia/config.toml"
check_link "$TARGET/.config/starship.toml" "$ROOT/dotfiles/starship/.config/starship.toml"
check_link "$TARGET/.config/tmux/tmux.conf" "$ROOT/dotfiles/tmux/.config/tmux/tmux.conf"
check_link "$TARGET/.local/bin/deomarchyfy-launch-terminal" \
  "$ROOT/dotfiles/hyprland/.local/bin/deomarchyfy-launch-terminal"

printf '\nChecking workstation services\n'
check_service NetworkManager.service
check_service firewalld.service
check_service power-profiles-daemon.service
check_service fstrim.timer
check_service tailscaled.service
check_service bluetooth.service
check_service docker.service
check_firewalld_zone

if [[ " $(id -nG) " == *' docker '* ]]; then
  pass 'current user belongs to the docker group'
else
  fail 'current user is not in the docker group; log in again after running the service script'
fi

if $require_ssh; then
  check_service sshd.service
  if firewall-cmd --zone=home --query-service=ssh >/dev/null 2>&1; then
    pass 'SSH is allowed in firewalld home zone'
  else
    fail 'SSH is not allowed in firewalld home zone'
  fi
  if [[ -s "$TARGET/.ssh/authorized_keys" ]]; then
    pass 'SSH authorized_keys contains a key'
  else
    fail 'SSH authorized_keys is missing or empty'
  fi
fi

if $require_accountsservice; then
  check_service accounts-daemon.service
fi

if $require_zram; then
  expected_zram=$'[zram0]\nzram-size = ram\ncompression-algorithm = zstd\n'
  if [[ -f /etc/systemd/zram-generator.conf ]] && \
     cmp -s /etc/systemd/zram-generator.conf <(printf '%s' "$expected_zram"); then
    pass 'zram-generator configuration matches the reviewed contents'
  else
    fail 'zram-generator configuration is missing or differs from the reviewed contents'
  fi
  if swapon --show=NAME --noheadings 2>/dev/null | tr -d ' ' | grep -Fxq /dev/zram0; then
    pass 'active swap device is /dev/zram0'
  else
    fail '/dev/zram0 is not active swap; reboot after configuring zram'
  fi
fi

printf '\nChecking Hyprland and Noctalia runtime\n'
check_hyprland_runtime
if noctalia config validate >/dev/null 2>&1; then
  pass 'Noctalia configuration is valid'
else
  fail 'Noctalia configuration validation failed'
fi
check_noctalia_lock_idle_settings

if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
  pass 'direct Hyprland Wayland session entry exists'
else
  fail 'direct Hyprland Wayland session entry is missing'
fi

if $require_login; then
  printf '\nChecking greetd and Noctalia Greeter\n'
  check_greeter_path
fi

printf '\nVerification complete: %d failure(s), %d warning(s).\n' "$failures" "$warnings"
if (( failures > 0 )); then
  exit 1
fi
