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

echo "==> Initializing bare repo at $DOTFILES_DIR"
git init --bare "$DOTFILES_DIR"
dotf remote add origin "$DOTFILES_REPO"
dotf config status.showUntrackedFiles no
dotf fetch origin
dotf remote set-head origin --auto 2>/dev/null || true

DEFAULT_BRANCH=$(dotf symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || true
: "${DEFAULT_BRANCH:=main}"

echo "==> Backing up conflicting files..."
for f in $(dotf ls-tree -r --name-only "origin/$DEFAULT_BRANCH"); do
    if [ -e "$HOME/$f" ]; then
        mkdir -p "$BACKUP/$(dirname "$f")"
        mv "$HOME/$f" "$BACKUP/$f"
        echo "  ~/$f"
    fi
done

if [ -d "$BACKUP" ]; then
    echo "  Saved to: $BACKUP"
else
    echo "  None found."
fi

echo "==> Checking out $DEFAULT_BRANCH"
dotf checkout -b "$DEFAULT_BRANCH" "origin/$DEFAULT_BRANCH"

if [ ! -f "$HOME/.config/dotf/env.conf" ]; then
    cp "$HOME/.config/dotf/env.conf.example" "$HOME/.config/dotf/env.conf"
    echo "==> Created ~/.config/dotf/env.conf (edit to customize)"
fi

echo ""
echo "Done! Open a new shell and run 'dotf help' to get started."
