#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOTFILES="${ROOT}/dotfiles"
readonly TARGET="${HOME:?HOME must be set}"

declare -a packages=(bash ghostty herdr hyprland tmux)
custom_packages=false
restow=false
dry_run=false

usage() {
  printf 'Usage: %s [--dry-run] [--restow] [package ...]\n' "${0##*/}"
  printf '\nPackages default to: %s\n' "${packages[*]}"
  printf '%s\n' \
    '  --dry-run  Show Stow changes without modifying $HOME' \
    '  --restow   Recreate links and remove obsolete links' \
    '  -h, --help Show this help'
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
    --restow)
      restow=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      die "unknown option: $1"
      ;;
    *)
      if [[ "$1" == 'noctalia' ]]; then
        die 'Noctalia configuration is intentionally managed manually'
      fi
      if ! $custom_packages; then
        packages=()
        custom_packages=true
      fi
      packages+=("$1")
      ;;
  esac
  shift
done

command -v stow >/dev/null 2>&1 || die 'GNU Stow is not installed; install the stow package first'
[[ -d "$DOTFILES" ]] || die "dotfiles directory not found: $DOTFILES"
[[ -d "$TARGET" ]] || die "target home directory not found: $TARGET"

declare -a stow_args=(--dir "$DOTFILES" --target "$TARGET")
if $restow; then
  stow_args+=(--restow)
fi

for package in "${packages[@]}"; do
  [[ "$package" =~ ^[a-z0-9_-]+$ ]] || die "invalid package name: $package"
  [[ -d "$DOTFILES/$package" ]] || die "unknown Stow package: $package"
done

printf 'Preflight for %s -> %s\n' "${packages[*]}" "$TARGET"
stow "${stow_args[@]}" --simulate --verbose=1 "${packages[@]}"

if $dry_run; then
  printf 'Dry run complete; no files were changed.\n'
  exit 0
fi

stow "${stow_args[@]}" "${packages[@]}"
printf 'Stow complete. Noctalia configuration was not changed.\n'
