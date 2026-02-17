#!/usr/bin/env bash
# Install dotfiles bare repo on a new machine.
# Usage: curl -Lfs https://raw.githubusercontent.com/technobok/dotfiles/main/.config/dot/install.sh | bash
#   or:  bash install.sh [repo-url]

set -euo pipefail

DOTFILES_REPO="${1:-git@github.com:technobok/dotfiles.git}"
DOTFILES_DIR="$HOME/.dotfiles"

dot() { git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"; }

if [ -d "$DOTFILES_DIR" ]; then
    echo "Error: $DOTFILES_DIR already exists. Remove it first."
    exit 1
fi

echo "==> Initializing dotfiles bare repo at $DOTFILES_DIR"
git init --bare "$DOTFILES_DIR"
dot remote add origin "$DOTFILES_REPO"
dot config status.showUntrackedFiles no

echo "==> Fetching from $DOTFILES_REPO"
dot fetch origin
dot remote set-head origin --auto 2>/dev/null || true

# Detect default branch
DEFAULT_BRANCH=$(dot symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || true
: "${DEFAULT_BRANCH:=main}"

echo "==> Installing dotfiles (branch: $DEFAULT_BRANCH)"

# All files from the remote branch
incoming=$(dot ls-tree -r --name-only "origin/$DEFAULT_BRANCH")

# Back up any existing files (same pattern as dot pull)
ts=$(date +%Y%m%d-%H%M%S)
backup="$HOME/.config/dot/backup/$ts"
backed_up=0

echo "==> Backing up existing files..."
while IFS= read -r f; do
    if [ -f "$HOME/$f" ]; then
        mkdir -p "$backup/$(dirname "$f")"
        mv "$HOME/$f" "$backup/$f"
        echo "  Backed up: ~/$f"
        backed_up=1
    fi
done <<< "$incoming"

if [ "$backed_up" -eq 1 ]; then
    echo "  Saved to: $backup"
else
    echo "  No conflicting files found."
fi

# Create local branch tracking remote and checkout
echo "==> Checking out $DEFAULT_BRANCH"
dot checkout -b "$DEFAULT_BRANCH" "origin/$DEFAULT_BRANCH"

echo ""
echo "Done! Open a new shell and run 'dot help' to get started."
