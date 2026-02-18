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

# List tracked files (no --work-tree needed for ls-tree)
files=$(git --git-dir="$DOTFILES_DIR" ls-tree -r --name-only HEAD)
if [ -z "$files" ]; then
    echo "Error: no tracked files found in repo"
    exit 1
fi

echo "==> Backing up conflicting files..."
for f in $files; do
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

echo "==> Checking out"
dotf checkout

if [ ! -f "$HOME/.config/dotf/env.conf" ]; then
    cp "$HOME/.config/dotf/env.conf.example" "$HOME/.config/dotf/env.conf"
    echo "==> Created ~/.config/dotf/env.conf (edit to customize)"
fi

echo ""
echo "Done! Open a new shell and run 'dotf help' to get started."
