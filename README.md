# dotfiles

Bare-repo dotfiles managed with a `dot` alias. One set of config files shared across the host and Docker dev environments.

## Quick start (new machine)

```bash
curl -Lfs https://raw.githubusercontent.com/technobok/dotfiles/master/.config/bootstrap.sh | bash
```

Or if you prefer to inspect first:

```bash
curl -LfO https://raw.githubusercontent.com/technobok/dotfiles/master/.config/bootstrap.sh
less bootstrap.sh
bash bootstrap.sh
```

Then open a new shell. The `dot` command is available in both bash and fish.

## How it works

The bootstrap script:

1. Clones this repo as a **bare** git repo into `~/.dotfiles`
2. Checks out the files directly into `$HOME` (e.g. `~/.bashrc`, `~/.config/fish/config.fish`)
3. If any files conflict, backs them up to `~/.dotfiles-backup/` before overwriting
4. Sets `status.showUntrackedFiles no` so `dot status` only shows tracked dotfiles, not every file in `$HOME`

After checkout, the shell configs define a `dot` function that wraps git with the bare repo:

```
dot status        = git --git-dir=~/.dotfiles --work-tree=~ status
dot add .bashrc   = git --git-dir=~/.dotfiles --work-tree=~ add .bashrc
```

Run `dot help` for a quick reference.

## Daily usage

```bash
# See what changed
dot status
dot diff

# Commit a change
dot add .bashrc
dot commit -m "update bashrc"
dot push

# See tracked files
dot ls-files
```

## Per-environment config

Set `DOTFILES_ENV` to control environment-specific behavior (e.g. in the Dockerfile or docker-compose.yml):

| Value | Keychain | Tmux auto-launch |
|-------|----------|------------------|
| `host` | no | no |
| `devai` | no | no |
| `devenv` | yes | yes |
| `webreports` | no | yes |

## What's tracked

```
.bashrc                     # bash config
.config/fish/config.fish    # fish config
.config/nvim/init.lua       # neovim config
.tmux.conf                  # tmux config
.config/bootstrap.sh        # setup script (checked out to ~/.config/)
```
