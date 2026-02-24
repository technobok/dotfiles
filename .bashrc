# ~/.bashrc

[ -z "$PS1" ] && return
export HISTCONTROL=ignoreboth
shopt -s checkwinsize

# Load env.conf (bash can source KEY=VALUE natively)
if [ -f ~/.config/dotf/env.conf ]; then
    eval "$(grep -v '^\s*#' ~/.config/dotf/env.conf | grep -v '^\s*$')"
fi

# Defaults for unset variables
: "${AUTOSTART_TMUX:=true}"
: "${TMUX_SESSION_NAME:=main}"
: "${SETUP_KEYCHAIN:=false}"
: "${INSTALL_FZF:=true}"
: "${INSTALL_NVIM:=true}"

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Extra PATH entries from config (colon-separated)
if [ -n "$EXTRA_PATH" ]; then
    export PATH="$EXTRA_PATH:$PATH"
fi

# Environment
export XDG_CONFIG_HOME="$HOME/.config"
export TZ=Australia/Brisbane
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export TERM=xterm-256color

# fzf
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash)"
    export FZF_DEFAULT_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --height 40% --layout=reverse --border"
elif [ "$INSTALL_FZF" = "true" ]; then
    echo "fzf not found. To install, run: install-fzf"
fi

install-fzf() {
    if command -v fzf >/dev/null 2>&1; then
        echo "fzf is already installed."
        return 0
    fi
    local version url tmpfile
    version=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    if [ -z "$version" ]; then
        echo "Error: could not determine latest fzf version."
        return 1
    fi
    url="https://github.com/junegunn/fzf/releases/download/${version}/fzf-${version#v}-linux_amd64.tar.gz"
    tmpfile=$(mktemp /tmp/fzf.XXXXXX.tar.gz)
    echo "==> Downloading fzf ${version}..."
    curl -fLo "$tmpfile" "$url" || { rm -f "$tmpfile"; return 1; }
    echo "==> Installing to ~/.local/bin..."
    mkdir -p ~/.local/bin
    tar -xzf "$tmpfile" -C ~/.local/bin fzf || { rm -f "$tmpfile"; echo "Installation failed."; return 1; }
    rm -f "$tmpfile"
    echo "fzf installed. Restart your shell to activate."
}

dotf() {
    if [ $# -eq 0 ] || [ "$1" = "help" ]; then
        echo "dotf - bare-repo dotfiles manager (git --git-dir=~/.dotfiles --work-tree=~)"
        echo ""
        echo "Usage: dotf <git-command> [args...]"
        echo ""
        echo "Examples:"
        echo "  dotf status              Show changed dotfiles"
        echo "  dotf diff                Diff working tree vs last commit"
        echo "  dotf add .bashrc         Stage a file for commit"
        echo "  dotf commit -am 'msg'    Stage all changed files & commit"
        echo "  dotf pull                Pull & auto-backup conflicting files"
        echo "  dotf push                Push to remote"
        echo "  dotf log --oneline       View commit history"
        echo "  dotf ls-files            List tracked dotfiles"
        return 0
    fi
    if [ "$1" = "pull" ]; then
        shift
        _dotf_pull "$@"
        return
    fi
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}

_dotf_pull() {
    local git_cmd="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

    echo "==> Fetching..."
    $git_cmd fetch "$@"

    local upstream
    upstream=$($git_cmd rev-parse --abbrev-ref '@{upstream}' 2>/dev/null) || true
    if [ -z "$upstream" ]; then
        echo "Error: no upstream branch configured. Run: dotf branch -u origin/main"
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
    backup="$HOME/.config/dotf/backup/$ts"

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

# keychain - just start/inherit the agent, don't preload keys
# keys are added on first use via AddKeysToAgent in ssh config
if [ "$SETUP_KEYCHAIN" = "true" ]; then
    eval "$(keychain --eval)"
fi

# Auto-launch tmux
if [ "$AUTOSTART_TMUX" = "true" ] && [ -z "$TMUX" ]; then
    tmux attach-session -t "$TMUX_SESSION_NAME" || tmux new-session -s "$TMUX_SESSION_NAME"
fi
