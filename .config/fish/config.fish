# ~/.config/fish/config.fish

if status is-interactive
    # Read ~/.config/env.conf into fish variables (skip comments and blank lines)
    set -l conf_file ~/.config/dotf/env.conf
    if test -f $conf_file
        while read -l line
            string match -rq '^\s*#' -- $line; and continue
            string match -rq '^\s*$' -- $line; and continue
            set -l key (string replace -r '=.*' '' -- $line)
            set -l val (string replace -r '^[^=]*=' '' -- $line)
            set -g $key $val
        end <$conf_file
    end

    # Defaults for unset variables
    set -q AUTOSTART_TMUX; or set -g AUTOSTART_TMUX true
    set -q TMUX_SESSION_NAME; or set -g TMUX_SESSION_NAME main
    set -q SETUP_KEYCHAIN; or set -g SETUP_KEYCHAIN false
    set -q KEYCHAIN_KEYS; or set -g KEYCHAIN_KEYS ~/.ssh/id_rsa_github

    # PATH
    fish_add_path /opt/nvim-linux-x86_64/bin
    fish_add_path ~/.local/bin

    # Extra PATH entries from config (colon-separated)
    if set -q EXTRA_PATH; and test -n "$EXTRA_PATH"
        for p in (string split ':' -- $EXTRA_PATH)
            fish_add_path $p
        end
    end

    # fzf integration
    fzf_key_bindings

    # Use bat for fzf previews
    set -x FZF_DEFAULT_OPTS "--preview 'bat --style=numbers --color=always --line-range :500 {}'"

    # Use ripgrep for fzf if available
    if type -q rg
        set -x FZF_DEFAULT_COMMAND 'rg --files --hidden --glob "!.git/*"'
    end

    alias n="nvim"

    function dotf
        if test (count $argv) -eq 0 -o "$argv[1]" = "help"
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
        end
        if test "$argv[1]" = pull
            _dotf_pull $argv[2..]
            return
        end
        git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" $argv
    end

    function _dotf_pull
        set -l git_cmd git --git-dir="$HOME/.dotfiles" --work-tree="$HOME"

        echo "==> Fetching..."
        $git_cmd fetch $argv

        set -l upstream ($git_cmd rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
        if test (count $upstream) -eq 0
            echo "Error: no upstream branch configured. Run: dotf branch -u origin/main"
            return 1
        end

        set -l incoming ($git_cmd diff --name-only HEAD.."$upstream")
        if test (count $incoming) -eq 0
            echo "Already up to date."
            return 0
        end

        echo "==> Incoming changes:"
        for f in $incoming
            echo "  $f"
        end

        set -l ts (date +%Y%m%d-%H%M%S)
        set -l backup "$HOME/.config/dotf/backup/$ts"
        set -l backed_up 0

        echo "==> Backing up existing files..."
        for f in $incoming
            if test -f "$HOME/$f"
                mkdir -p "$backup/"(dirname "$f")
                cp "$HOME/$f" "$backup/$f"
                echo "  Backed up: ~/$f"
                set backed_up 1
                # Remove untracked files so merge can place new ones
                if not $git_cmd ls-files --error-unmatch "$f" >/dev/null 2>&1
                    rm "$HOME/$f"
                end
            end
        end

        if test "$backed_up" -eq 1
            echo "  Saved to: $backup"
        else
            echo "  No files to back up."
        end

        echo "==> Merging..."
        $git_cmd merge "$upstream"
    end

    # Keychain for SSH key management
    if test "$SETUP_KEYCHAIN" = true
        keychain --eval $KEYCHAIN_KEYS | source
        set -l keychain_env "$HOME/.keychain/"(hostname)"-fish"
        if test -f "$keychain_env"
            source "$keychain_env"
        end
    end

    # Auto-launch tmux
    if test "$AUTOSTART_TMUX" = true; and not set -q TMUX
        tmux attach-session -t $TMUX_SESSION_NAME; or tmux new-session -s $TMUX_SESSION_NAME
    end
end
