#!/usr/bin/env bash
# Install dotfiles bare repo on a new machine.
# Usage: curl -Lfs https://raw.githubusercontent.com/technobok/dotfiles/main/.config/dotf/install.sh | bash
#   or:  bash install.sh [repo-url]

set -euo pipefail

DOTFILES_REPO="${1:-git@github.com:technobok/dotfiles.git}"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP="$HOME/.config/dotf/backup/$(date +%Y%m%d-%H%M%S)"

dotf() { git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"; }

if [ -d "$DOTFILES_DIR" ]; then
    echo "Error: $DOTFILES_DIR already exists. Remove it first."
    exit 1
fi

echo "==> Cloning bare repo into $DOTFILES_DIR"
git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
dotf config status.showUntrackedFiles no

echo "==> Checking out"
if checkout_err=$(dotf checkout 2>&1); then
    echo "  No conflicting files."
else
    # Parse conflicting filenames from git's error output (tab-indented lines)
    conflicting=$(echo "$checkout_err" | sed -n 's/^\t//p')
    if [ -z "$conflicting" ]; then
        echo "Checkout failed for an unexpected reason:"
        echo "$checkout_err"
        exit 1
    fi

    echo "==> Backing up conflicting files..."
    while IFS= read -r f; do
        mkdir -p "$BACKUP/$(dirname "$f")"
        mv "$HOME/$f" "$BACKUP/$f"
        echo "  ~/$f"
    done <<< "$conflicting"
    echo "  Saved to: $BACKUP"

    dotf checkout
fi

if [ ! -f "$HOME/.config/dotf/env.conf" ]; then
    cp "$HOME/.config/dotf/env.conf.example" "$HOME/.config/dotf/env.conf"
    echo "==> Created ~/.config/dotf/env.conf (edit to customize)"
fi

echo ""
echo "Done! Open a new shell and run 'dotf help' to get started."
