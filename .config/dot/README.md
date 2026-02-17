# dotfiles

Bare-repo dotfiles managed with a `dot` alias. One set of config files shared across the host and Docker dev environments.

## Quick start (new machine)

```bash
curl -Lfs https://raw.githubusercontent.com/technobok/dotfiles/main/.config/dot/install.sh | bash
```

Or if you prefer to inspect first:

```bash
curl -LfO https://raw.githubusercontent.com/technobok/dotfiles/main/.config/dot/install.sh
less install.sh
bash install.sh
```

Then open a new shell. The `dot` command is available in both bash and fish.

## How it works

The install script:

1. Initializes a **bare** git repo at `~/.dotfiles`
2. Fetches and checks out files directly into `$HOME` (e.g. `~/.bashrc`, `~/.config/fish/config.fish`)
3. If any files conflict, backs them up to `~/.config/dot/backup/<timestamp>/` before overwriting
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

# Pull updates (auto-backs up conflicting files)
dot pull

# Commit a change
dot add .bashrc
dot commit -m "update bashrc"
dot push

# See tracked files
dot ls-files
```

## Per-host configuration

The install script creates `~/.config/dot/env.conf` from the example. Edit it for your environment:

```bash
vim ~/.config/dot/env.conf
```

| Key | Default | Description |
|-----|---------|-------------|
| `AUTOSTART_TMUX` | `true` | Launch tmux on interactive shell login |
| `TMUX_SESSION_NAME` | `main` | Tmux session name to attach/create |
| `SETUP_KEYCHAIN` | `false` | Run keychain for SSH key management |
| `KEYCHAIN_KEYS` | `~/.ssh/id_rsa_github` | Space-separated keys for keychain |
| `EXTRA_PATH` | _(empty)_ | Colon-separated extra PATH directories |
| `GEMINI_NVIM` | `false` | Enable gemini-cli.nvim in Neovim |

## Uninstall

Remove the bare repo and backups. Config files stay in place:

```bash
rm -rf ~/.dotfiles ~/.config/dot/backup
```

## What's tracked

```
.bashrc                         # bash config
.config/fish/config.fish        # fish config
.config/nvim/init.lua           # neovim config
.config/tmux/tmux.conf          # tmux config (XDG, requires tmux >= 3.1)
.config/dot/env.conf.example    # per-host config template
.config/dot/install.sh          # install script
.config/dot/README.md           # this file
```
