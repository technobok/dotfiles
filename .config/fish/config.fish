# ~/.config/fish/config.fish

if status is-interactive
    # Read ~/.config/env.conf into fish variables (skip comments and blank lines)
    set -l conf_file ~/.config/env.conf
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

    function dot
        if test (count $argv) -eq 0 -o "$argv[1]" = "help"
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
        end
        git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" $argv
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
