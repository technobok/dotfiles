# ~/.bashrc

[ -z "$PS1" ] && return
export HISTCONTROL=ignoreboth
shopt -s checkwinsize

# Load env.conf (bash can source KEY=VALUE natively)
if [ -f ~/.config/env.conf ]; then
    eval "$(grep -v '^\s*#' ~/.config/env.conf | grep -v '^\s*$')"
fi

# Defaults for unset variables
: "${AUTOSTART_TMUX:=true}"
: "${TMUX_SESSION_NAME:=main}"
: "${SETUP_KEYCHAIN:=false}"
: "${KEYCHAIN_KEYS:=~/.ssh/id_rsa_github}"

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Extra PATH entries from config (colon-separated)
if [ -n "$EXTRA_PATH" ]; then
    export PATH="$EXTRA_PATH:$PATH"
fi

# Environment
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export TERM=xterm-256color

# fzf
export FZF_DEFAULT_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --height 40% --layout=reverse --border"
[ -f "$HOME/.fzf_scripts/completion.bash" ] && source "$HOME/.fzf_scripts/completion.bash"
[ -f "$HOME/.fzf_scripts/key-bindings.bash" ] && source "$HOME/.fzf_scripts/key-bindings.bash"

dot() {
    if [ $# -eq 0 ] || [ "$1" = "help" ]; then
        echo "dot - bare-repo dotfiles manager (git --git-dir=~/.dotfiles --work-tree=~)"
        echo ""
        echo "Usage: dot <git-command> [args...]"
        echo ""
        echo "Examples:"
        echo "  dot status              Show changed dotfiles"
        echo "  dot diff                Diff working tree vs last commit"
        echo "  dot add .bashrc         Stage a file"
        echo "  dot commit -m 'msg'     Commit staged changes"
        echo "  dot push                Push to remote"
        echo "  dot log --oneline       View commit history"
        echo "  dot ls-files            List tracked dotfiles"
        return 0
    fi
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}

# Auto-launch tmux
if [ "$AUTOSTART_TMUX" = "true" ] && [ -z "$TMUX" ]; then
    tmux attach-session -t "$TMUX_SESSION_NAME" || tmux new-session -s "$TMUX_SESSION_NAME"
fi
