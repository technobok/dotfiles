# ~/.bashrc
# Unified dotfiles config. Set DOTFILES_ENV to: host, devai, devenv, webreports

[ -z "$PS1" ] && return
export HISTCONTROL=ignoreboth
shopt -s checkwinsize

export PATH="$HOME/.local/bin:$PATH"

export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export TERM=xterm-256color

# fzf: bat preview + popup style
export FZF_DEFAULT_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --height 40% --layout=reverse --border"

# Source fzf completion and key-bindings
[ -f "$HOME/.fzf_scripts/completion.bash" ] && source "$HOME/.fzf_scripts/completion.bash"
[ -f "$HOME/.fzf_scripts/key-bindings.bash" ] && source "$HOME/.fzf_scripts/key-bindings.bash"

alias dot="git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME"

# devenv + webreports: auto-launch tmux
if [ "$DOTFILES_ENV" = "devenv" ] || [ "$DOTFILES_ENV" = "webreports" ]; then
    if [ -z "$TMUX" ]; then
        tmux attach-session -t dev || tmux new-session -s dev
    fi
fi
