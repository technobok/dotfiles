#!/usr/bin/env bash
# Bootstrap dotfiles bare repo on a new machine.
# Usage: curl -Lfs https://raw.githubusercontent.com/technobok/dotfiles/master/.config/bootstrap.sh | bash
#   or:  bash bootstrap.sh [repo-url]

set -euo pipefail

DOTFILES_REPO="${1:-git@github.com:technobok/dotfiles.git}"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup"

dot() { git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"; }

if [ -d "$DOTFILES_DIR" ]; then
    echo "Error: $DOTFILES_DIR already exists. Remove it first."
    exit 1
fi

echo "Cloning dotfiles into bare repo at $DOTFILES_DIR..."
git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"

echo "Backing up existing files to $BACKUP_DIR..."
backed_up=0
dot ls-tree -r --name-only HEAD | while read -r f; do
    if [ -f "$HOME/$f" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$f")"
        mv "$HOME/$f" "$BACKUP_DIR/$f"
        backed_up=1
    fi
done
if [ -d "$BACKUP_DIR" ]; then
    echo "Backed up files to $BACKUP_DIR"
else
    echo "No existing files to back up"
fi

echo "Checking out dotfiles..."
dot checkout

dot config status.showUntrackedFiles no

echo ""
echo "Done! Open a new shell and run 'dot help' to get started."
