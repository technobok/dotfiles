#!/usr/bin/env bash
# Bootstrap dotfiles bare repo on a new machine.
# Usage: curl -Lfs <raw-url>/bootstrap.sh | bash
#   or:  bash bootstrap.sh <repo-url>

set -euo pipefail

DOTFILES_REPO="${1:-git@github.com:CHANGEME/dotfiles.git}"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup"

dot() { git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"; }

if [ -d "$DOTFILES_DIR" ]; then
    echo "Error: $DOTFILES_DIR already exists. Remove it first."
    exit 1
fi

echo "Cloning dotfiles into bare repo at $DOTFILES_DIR..."
git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"

echo "Checking out dotfiles..."
if ! dot checkout 2>/dev/null; then
    echo "Backing up conflicting files to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    dot checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' | while read -r f; do
        mkdir -p "$BACKUP_DIR/$(dirname "$f")"
        mv "$HOME/$f" "$BACKUP_DIR/$f"
    done
    dot checkout
fi

dot config status.showUntrackedFiles no

echo "Done. Use 'dot' alias to manage dotfiles:"
echo "  dot status"
echo "  dot add .bashrc"
echo "  dot commit -m 'update bashrc'"
echo "  dot push"
