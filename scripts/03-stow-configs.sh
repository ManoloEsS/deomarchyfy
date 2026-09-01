#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOTFILES="${ROOT}/dotfiles"
readonly TARGET="${HOME:?HOME must be set}"

declare -a packages=(bash ghostty herdr hyprland tmux)
declare -a bash_backup_files=()
declare -a bash_conflicting_files=()
custom_packages=false
restow=false
dry_run=false
bash_skip=false
bash_backup=false
bash_replace=false

usage() {
  printf 'Usage: %s [--dry-run] [--restow] [--replace-bash] [package ...]\n' "${0##*/}"
  printf '\nPackages default to: %s\n' "${packages[*]}"
  printf '%s\n' \
    '  --dry-run       Show Stow changes without modifying $HOME' \
    '  --restow        Recreate links and remove obsolete links' \
    '  --replace-bash  Back up and replace existing Bash files' \
    '  Bash defaults are preserved unless --replace-bash is supplied' \
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
    --replace-bash)
      bash_replace=true
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

declare -a stow_args=(
  --dir "$DOTFILES"
  --target "$TARGET"
  --no-folding
  --ignore '^\.local/(share|state)(/|$)'
)
if $restow; then
  stow_args+=(--restow)
fi

for package in "${packages[@]}"; do
  [[ "$package" =~ ^[a-z0-9_-]+$ ]] || die "invalid package name: $package"
  [[ -d "$DOTFILES/$package" ]] || die "unknown Stow package: $package"
done

migrate_folded_runtime_data() {
  local target_local source_local relative source_path target_path

  target_local="$TARGET/.local"
  source_local="$DOTFILES/hyprland/.local"
  [[ -L "$target_local" ]] || return 0
  [[ "$(readlink -f "$target_local")" == "$(readlink -f "$source_local")" ]] || return 0

  for relative in share state; do
    source_path="$source_local/$relative"
    [[ -e "$source_path" ]] || continue
    if $dry_run; then
      printf 'Would move runtime data %s -> %s/%s\n' "$source_path" "$target_local" "$relative"
    fi
  done

  if $dry_run; then
    return 0
  fi

  # The old folded link makes runtime paths resolve into the repository. Remove
  # only that exact link before moving the generated directories back to $HOME.
  rm -- "$target_local"
  mkdir -- "$target_local"
  for relative in share state; do
    source_path="$source_local/$relative"
    target_path="$target_local/$relative"
    [[ -e "$source_path" ]] || continue
    [[ ! -e "$target_path" && ! -L "$target_path" ]] || die \
      "cannot migrate runtime data; target already exists: $target_path"
    mv -- "$source_path" "$target_path"
  done
  printf 'Moved folded runtime data out of the repository.\n'
}

migrate_folded_runtime_data

inspect_bash_targets() {
  local file target source

  for file in .bashrc .bash_profile .profile .bash_aliases .bash_functions .inputrc; do
    target="$TARGET/$file"
    source="$DOTFILES/bash/$file"
    [[ -e "$source" || -L "$source" ]] || continue
    [[ -e "$target" || -L "$target" ]] || continue

    if [[ -L "$target" ]] && [[ "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
      continue
    fi

    if $bash_replace; then
      bash_backup_files+=("$file")
    elif [[ -f "$target" ]] && cmp -s "$target" "$source"; then
      bash_backup_files+=("$file")
    else
      bash_conflicting_files+=("$file")
    fi
  done

  if ((${#bash_conflicting_files[@]} > 0)); then
    bash_skip=true
    printf 'warning: preserving customized Bash files and skipping bash Stow package:\n' >&2
    printf '  %s\n' "${bash_conflicting_files[*]}" >&2
    printf 'Resolve these files, then rerun this script to apply Bash.\n' >&2
  elif ((${#bash_backup_files[@]} > 0)); then
    bash_backup=true
    if $bash_replace; then
      printf 'Existing Bash files will be backed up and replaced before Stow:\n'
    else
      printf 'Bash files already match the repository and will be backed up before Stow:\n'
    fi
    printf '  %s\n' "${bash_backup_files[*]}"
  fi
}

backup_bash_files() {
  local backup_dir file

  backup_dir="$TARGET/.config/deomarchyfy-backup/bash-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  for file in "${bash_backup_files[@]}"; do
    mv -- "$TARGET/$file" "$backup_dir/$file"
  done
  printf 'Backed up existing Bash files to %s\n' "$backup_dir"
}

if [[ " ${packages[*]} " == *' bash '* ]]; then
  inspect_bash_targets
fi

declare -a preflight_packages=()
for package in "${packages[@]}"; do
  if [[ "$package" == 'bash' ]] && ($bash_skip || $bash_backup); then
    continue
  fi
  preflight_packages+=("$package")
done

if ((${#preflight_packages[@]} > 0)); then
  printf 'Preflight for %s -> %s\n' "${preflight_packages[*]}" "$TARGET"
  stow "${stow_args[@]}" --simulate --verbose=1 "${preflight_packages[@]}"
else
  printf 'No non-conflicting Stow packages require a preflight.\n'
fi

if $dry_run; then
  if $bash_skip; then
    printf 'Dry run complete; bash was skipped because customized files were preserved.\n'
  elif $bash_backup; then
    if $bash_replace; then
      printf 'Dry run complete; existing Bash files would be backed up and replaced.\n'
    else
      printf 'Dry run complete; matching Bash files would be backed up before Stow.\n'
    fi
  else
    printf 'Dry run complete; no files were changed.\n'
  fi
  exit 0
fi

if $bash_backup; then
  backup_bash_files
fi

if ((${#packages[@]} == 0)); then
  printf 'No Stow packages selected.\n'
  exit 0
fi

if $bash_skip; then
  declare -a apply_packages=()
  for package in "${packages[@]}"; do
    [[ "$package" == 'bash' ]] || apply_packages+=("$package")
  done
else
  declare -a apply_packages=("${packages[@]}")
fi

if ((${#apply_packages[@]} > 0)); then
  stow "${stow_args[@]}" "${apply_packages[@]}"
fi

if $bash_skip; then
  printf 'Stow complete; Bash was skipped. Noctalia configuration was not changed.\n'
else
  printf 'Stow complete. Noctalia configuration was not changed.\n'
fi
