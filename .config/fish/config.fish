# ~/.config/fish/config.fish
# Unified dotfiles config. Set DOTFILES_ENV to: host, devai, devenv, webreports

if status is-interactive
    fish_add_path /opt/nvim-linux-x86_64/bin
    fish_add_path ~/.local/bin

    # fzf integration
    fzf_key_bindings

    # Use bat for fzf previews
    set -x FZF_DEFAULT_OPTS "--preview 'bat --style=numbers --color=always --line-range :500 {}'"

    # Use ripgrep for fzf if available
    if type -q rg
        set -x FZF_DEFAULT_COMMAND 'rg --files --hidden --glob "!.git/*"'
    end

    alias n="nvim"
    alias dot="git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME"

    # devenv: keychain for SSH keys
    if test "$DOTFILES_ENV" = "devenv"
        keychain --eval ~/.ssh/id_rsa_github | source
        set -l keychain_env "$HOME/.keychain/(hostname)-fish"
        if test -f "$keychain_env"
            source "$keychain_env"
        end
    end

    # devenv + webreports: auto-launch tmux
    if test "$DOTFILES_ENV" = "devenv" -o "$DOTFILES_ENV" = "webreports"
        if not set -q TMUX
            tmux attach-session -t main; or tmux new-session -s main
        end
    end
end
