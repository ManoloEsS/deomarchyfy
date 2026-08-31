# Select a file with fzf and preview it with bat. This stays terminal-neutral.
ff() {
  fzf --preview 'bat --style=numbers --color=always {}' "$@"
}

eff() {
  local file
  file="$(ff "$@")" || return
  [[ -n "${file}" ]] || return
  "${EDITOR}" "${file}"
}

sff() {
  if (( $# == 0 )); then
    echo "Usage: sff <destination> (e.g. sff host:/tmp/)"
    return 1
  fi

  local file
  file="$(find . -type f -printf '%T@\t%p\n' | sort -rn | cut -f2- | ff)" || return
  [[ -n "${file}" ]] && scp "${file}" "$1"
}

if command -v zoxide >/dev/null 2>&1; then
  zd() {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ -d "$1" ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then
        echo "Error: Directory not found"
        return 1
      fi

      printf "\U000F17A9 "
      pwd
    fi
  }
  alias cd='zd'
fi

open() (
  xdg-open "$@" >/dev/null 2>&1 &
)

rsw() {
  (( $# == 2 )) || { echo "Usage: rsw <source> <destination>"; return 1; }

  local src="${1%/}" dest="$2"
  local sockets="${XDG_RUNTIME_DIR:-${HOME}/.ssh/sockets}"
  mkdir -p "${sockets}"
  local rsh="ssh -o ControlMaster=auto -o ControlPath=${sockets}/rsw-%r@%h:%p -o ControlPersist=yes"

  setsid --fork env RSYNC_RSH="${rsh}" bash -c \
    'rsync -a "$1/" "$2"; while inotifywait -r -q -e modify,create,delete,move "$1"; do rsync -a "$1/" "$2"; done' \
    rsw-watch "${src}" "${dest}" >/dev/null 2>&1
  echo "Watching ${src} -> ${dest}"
}

lsw() {
  local pid cmd rest found=0
  while read -r pid cmd; do
    rest="${cmd##*rsw-watch }"
    echo "${pid}: ${rest% *} -> ${rest##* }"
    found=1
  done < <(pgrep -af 'rsw-watch ')
  (( found )) || echo "No active watches"
}

dsw() {
  local pid found=0
  for pid in $(pgrep -f 'rsw-watch '); do
    kill -- -"${pid}" 2>/dev/null && echo "Stopped watch (pid ${pid})" && found=1
  done
  (( found )) || echo "No active watches"
}

n() {
  if (( $# == 0 )); then
    command nvim .
  else
    command nvim "$@"
  fi
}
