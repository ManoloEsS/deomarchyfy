#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly SOURCE_DIR="${NOCTALIA_GREETER_DIR:-${HOME:?HOME must be set}/src/noctalia-greeter}"
readonly GREETER_TAG="${NOCTALIA_GREETER_TAG:-v1.3.0}"
readonly GREETER_COMMIT="${NOCTALIA_GREETER_COMMIT:-b4e668d4f8aada549d5c990c3a18458fae8be6b9}"

readonly -a build_packages=(
  greetd dbus meson gcc just
  wayland wayland-protocols wlroots0.20
  libglvnd freetype2 fontconfig
  cairo pango harfbuzz
  libxkbcommon glib2
  tomlplusplus nlohmann-json stb
  libwebp librsvg polkit
)

usage() {
  printf 'Usage: %s [options]\n' "$SCRIPT_NAME"
  printf '\n'
  printf '%s\n' \
    'Installs the pinned Noctalia Greeter build and prepares its system files.' \
    '' \
    'Options:' \
    '  --skip-deps  Do not install build dependencies' \
    '  -h, --help   Show this help'
  printf '\nSource directory: %s\n' "$SOURCE_DIR"
  printf 'Pinned tag: %s\n' "$GREETER_TAG"
  printf 'Pinned commit: %s\n' "$GREETER_COMMIT"
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

skip_deps=false

while (($# > 0)); do
  case "$1" in
    --skip-deps)
      skip_deps=true
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

if (( EUID == 0 )); then
  die 'run this script as the target user, not as root'
fi

command -v sudo >/dev/null 2>&1 || die 'sudo is not installed'
command -v git >/dev/null 2>&1 || die 'git is not installed'

if ! $skip_deps; then
  command -v pacman >/dev/null 2>&1 || die 'pacman is not installed'
  sudo -v
  sudo pacman -S --needed "${build_packages[@]}"
fi

if [[ -e "$SOURCE_DIR" ]]; then
  [[ -d "$SOURCE_DIR/.git" ]] || die "source directory is not a Git repository: $SOURCE_DIR"
  [[ -z "$(git -C "$SOURCE_DIR" status --porcelain)" ]] || die \
    "source directory has uncommitted changes: $SOURCE_DIR"
  [[ "$(git -C "$SOURCE_DIR" describe --tags --exact-match HEAD 2>/dev/null || true)" == "$GREETER_TAG" ]] || die \
    "source directory is not checked out at $GREETER_TAG: $SOURCE_DIR"
  [[ "$(git -C "$SOURCE_DIR" rev-parse HEAD)" == "$GREETER_COMMIT" ]] || die \
    "source directory is not at the expected commit: $SOURCE_DIR"
else
  mkdir -p "$(dirname -- "$SOURCE_DIR")"
  git clone --branch "$GREETER_TAG" --depth 1 \
    https://github.com/noctalia-dev/noctalia-greeter.git \
    "$SOURCE_DIR"
fi

[[ "$(git -C "$SOURCE_DIR" rev-parse HEAD)" == "$GREETER_COMMIT" ]] || die \
  "checked-out source does not match the expected commit: $GREETER_COMMIT"

command -v just >/dev/null 2>&1 || die 'just is not installed; rerun without --skip-deps'
command -v meson >/dev/null 2>&1 || die 'meson is not installed; rerun without --skip-deps'

cd "$SOURCE_DIR"
just configure-release
just build-release
sudo meson install -C build-release
sudo ./scripts/setup_greeter_system.sh

command -v noctalia-greeter-session >/dev/null 2>&1 || die \
  'noctalia-greeter-session was not found after installation'
command -v noctalia-greeter >/dev/null 2>&1 || die \
  'noctalia-greeter was not found after installation'

printf 'Noctalia Greeter %s installed successfully.\n' "$GREETER_TAG"
printf 'Next: run scripts/05-configure-greetd.sh --dry-run, then configure greetd.\n'
