# File-system and navigation aliases.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias vim='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Personal tools.
alias c='opencode --auto'
alias d='docker'
alias t='tmux attach || tmux new -s Work'
alias h='herdr'
