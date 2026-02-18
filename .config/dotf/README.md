# dotfiles

Bare-repo dotfiles managed with a `dotf` alias. One set of config files shared across the host and Docker dev environments.

## Quick start (new machine)

```bash
curl -Lfs https://raw.githubusercontent.com/technobok/dotfiles/main/.config/dotf/install.sh | bash
```

Or if you prefer to inspect first:

```bash
curl -LfO https://raw.githubusercontent.com/technobok/dotfiles/main/.config/dotf/install.sh
less install.sh
bash install.sh
```

Then open a new shell. The `dotf` command is available in both bash and fish.

## How it works

The install script:

1. Initializes a **bare** git repo at `~/.dotfiles`
2. Fetches and checks out files directly into `$HOME` (e.g. `~/.bashrc`, `~/.config/fish/config.fish`)
3. If any files conflict, backs them up to `~/.config/dotf/backup/<timestamp>/` before overwriting
4. Sets `status.showUntrackedFiles no` so `dotf status` only shows tracked dotfiles, not every file in `$HOME`

After checkout, the shell configs define a `dotf` function that wraps git with the bare repo:

```
dotf status        = git --git-dir=~/.dotfiles --work-tree=~ status
dotf add .bashrc   = git --git-dir=~/.dotfiles --work-tree=~ add .bashrc
```

Run `dotf help` for a quick reference.

## Daily usage

```bash
# See what changed
dotf status
dotf diff

# Pull updates (auto-backs up conflicting files)
dotf pull

# Commit a change
dotf add .bashrc
dotf commit -m "update bashrc"

# Or stage all changed tracked files & commit in one step
dotf commit -am "update bashrc"
dotf push

# See tracked files
dotf ls-files
```

## Per-host configuration

The install script creates `~/.config/dotf/env.conf` from the example. Edit it for your environment:

```bash
vim ~/.config/dotf/env.conf
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
rm -rf ~/.dotfiles ~/.config/dotf/backup
```

## What's tracked

```
.bashrc                         # bash config
.config/fish/config.fish        # fish config
.config/nvim/init.lua           # neovim config
.config/tmux/tmux.conf          # tmux config (XDG, requires tmux >= 3.1)
.config/dotf/env.conf.example    # per-host config template
.config/dotf/install.sh          # install script
.config/dotf/README.md           # this file
```
