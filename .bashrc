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
        echo "  dot pull                Pull & auto-backup conflicting files"
        echo "  dot push                Push to remote"
        echo "  dot log --oneline       View commit history"
        echo "  dot ls-files            List tracked dotfiles"
        return 0
    fi
    if [ "$1" = "pull" ]; then
        shift
        _dot_pull "$@"
        return
    fi
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}

_dot_pull() {
    local git_cmd="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

    echo "==> Fetching..."
    $git_cmd fetch "$@"

    local upstream
    upstream=$($git_cmd rev-parse --abbrev-ref '@{upstream}' 2>/dev/null) || true
    if [ -z "$upstream" ]; then
        echo "Error: no upstream branch configured. Run: dot branch -u origin/main"
        return 1
    fi

    local incoming
    incoming=$($git_cmd diff --name-only HEAD.."$upstream")
    if [ -z "$incoming" ]; then
        echo "Already up to date."
        return 0
    fi

    echo "==> Incoming changes:"
    while IFS= read -r f; do
        echo "  $f"
    done <<< "$incoming"

    local ts backup backed_up=0
    ts=$(date +%Y%m%d-%H%M%S)
    backup="$HOME/.dotfiles-backup/$ts"

    echo "==> Backing up existing files..."
    while IFS= read -r f; do
        if [ -f "$HOME/$f" ]; then
            mkdir -p "$backup/$(dirname "$f")"
            cp "$HOME/$f" "$backup/$f"
            echo "  Backed up: ~/$f"
            backed_up=1
            # Remove untracked files so merge can place new ones
            if ! $git_cmd ls-files --error-unmatch "$f" >/dev/null 2>&1; then
                rm "$HOME/$f"
            fi
        fi
    done <<< "$incoming"

    if [ "$backed_up" -eq 1 ]; then
        echo "  Saved to: $backup"
    else
        echo "  No files to back up."
    fi

    echo "==> Merging..."
    $git_cmd merge "$upstream"
}

# Auto-launch tmux
if [ "$AUTOSTART_TMUX" = "true" ] && [ -z "$TMUX" ]; then
    tmux attach-session -t "$TMUX_SESSION_NAME" || tmux new-session -s "$TMUX_SESSION_NAME"
fi
