# ~/.config/fish/config.fish

set -g fish_greeting

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
    set -q INSTALL_FZF; or set -g INSTALL_FZF true
    set -q INSTALL_NVIM; or set -g INSTALL_NVIM true

    # PATH
    fish_add_path /opt/nvim-linux-x86_64/bin
    fish_add_path ~/.local/bin

    # Extra PATH entries from config (colon-separated)
    if set -q EXTRA_PATH; and test -n "$EXTRA_PATH"
        for p in (string split ':' -- $EXTRA_PATH)
            fish_add_path $p
        end
    end

    # Check for fzf and offer to install if missing
    if test "$INSTALL_FZF" = true; and not type -q fzf
        echo "fzf not found. To install, run: install-fzf"
    end

    function install-fzf
        if type -q fzf
            echo "fzf is already installed."
            return 0
        end
        set -l version (curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | string match -r '"tag_name": "([^"]*)"' | tail -1)
        if test -z "$version"
            echo "Error: could not determine latest fzf version."
            return 1
        end
        set -l url "https://github.com/junegunn/fzf/releases/download/$version/fzf-"(string replace 'v' '' $version)"-linux_amd64.tar.gz"
        set -l tmpfile (mktemp /tmp/fzf.XXXXXX.tar.gz)
        echo "==> Downloading fzf $version..."
        curl -Lo $tmpfile $url
        or begin; rm -f $tmpfile; return 1; end
        echo "==> Installing to ~/.local/bin..."
        mkdir -p ~/.local/bin
        tar -xzf $tmpfile -C ~/.local/bin fzf
        rm -f $tmpfile
        echo "fzf installed. Restart your shell to activate."
    end

    # Check for Neovim and offer to install if missing
    if test "$INSTALL_NVIM" = true; and not test -d /opt/nvim-linux-x86_64
        echo "Neovim not found in /opt. To install, run: install-nvim"
        echo "  (sudo credentials required to unpack into /opt)"
    end

    function install-nvim
        if test -d /opt/nvim-linux-x86_64
            echo "Neovim is already installed at /opt/nvim-linux-x86_64"
            return 0
        end
        set -l tmpfile (mktemp /tmp/nvim-linux-x86_64.XXXXXX.tar.gz)
        echo "==> Downloading Neovim..."
        curl -Lo $tmpfile https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        or begin; rm -f $tmpfile; return 1; end
        echo "==> Installing to /opt (sudo required)..."
        sudo tar -C /opt -xzf $tmpfile
        and rm -f $tmpfile
        and echo "Neovim installed. nvim is now available."
        or begin; rm -f $tmpfile; echo "Installation failed."; return 1; end
    end

    # fzf integration
    if type -q fzf
        fzf --fish | source
        set -x FZF_DEFAULT_OPTS "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
        if type -q rg
            set -x FZF_DEFAULT_COMMAND 'rg --files --hidden --glob "!.git/*"'
        end
    end

    # Solarized Dark: use base00 for visible autosuggestions
    set -g fish_color_autosuggestion 657b83

    set -x TZ Australia/Brisbane

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

        # Ensure fetch refspec exists (bare clones omit it)
        if not $git_cmd config --get remote.origin.fetch >/dev/null 2>&1
            $git_cmd config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
        end

        echo "==> Fetching..."
        $git_cmd fetch origin $argv

        # Ensure upstream tracking is set
        set -l upstream ($git_cmd rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
        if test (count $upstream) -eq 0
            set -l branch ($git_cmd branch --show-current)
            $git_cmd branch -u origin/$branch
            set upstream origin/$branch
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
