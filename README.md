# dotfiles

Generic dev setup (zsh, oh-my-zsh + powerlevel10k, tmux, vim, git, fzf) kept in a
bare Git repo with `$HOME` as the work tree. Works on macOS, Linux, VMs and containers.
Nothing work-related is tracked here; see **Work files** below.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/jnihal/dotfiles/main/.term-init.sh | bash
# add `-s -- --chsh` after `bash` to also make zsh the login shell
# GIT_NAME / GIT_EMAIL in the environment populate ~/.gitconfig.local
```

It installs missing packages (brew/apt/apk/dnf/yum/pacman; works as root without sudo),
oh-my-zsh, powerlevel10k, zsh-autosuggestions, fzf and tmux's plugin manager, then
checks out the dotfiles. Existing conflicting files are moved to `~/.dotfiles-backup`.
Re-running is safe. Optional tools such as `delta` are skipped with a warning when the
distro doesn't package them.

Notes:

- The script needs `bash`, which Alpine doesn't ship: run `apk add bash curl` first.
- The first `dnf`/`apt` run on a fresh container can take several minutes on a slow
  network or mirror; later runs reuse the package cache.
- `DOTFILES_REPO=<url or path>` clones from somewhere other than GitHub (handy for testing
  a change in a container before pushing it).

## Per-machine files (untracked)

- `~/.zshrc.local`, `~/.zprofile.local`: extra shell config and environment
- `~/.gitconfig.local`: git identity, URL rewrites, delta pager
- `~/.term-init.local`: optional hook that `.term-init.sh` sources *before* installing
  packages. Use it for things the install itself depends on, like package mirrors or
  proxies. It can use `$PM` (package manager), `as_root`, `log` and `warn`. Credentials
  should come from the environment (for example `docker run -e SOME_TOKEN`), not the file.
  Override its location with `TERM_INIT_LOCAL=<path>`.

## Work files

`~/.local/bin/dev-sync` keeps work-only files out of this repo: it tars the files
listed in `~/.config/dev-sync/manifest`, encrypts them (AES-256, passphrase) and copies
them to `DEV_SYNC_DEST` (a directory or `host:dir`). Setup: copy
`~/.config/dev-sync/config.example` to `config`, then:

```sh
dev-sync backup      # encrypt + upload
dev-sync restore     # download + decrypt + unpack (existing files saved aside)
dev-sync schedule    # daily backup via launchd/cron
```

On a new work machine or container, restore first so `~/.term-init.local` and the
other work files are in place, then run the install script. `dev-sync` is a single
file, so fetch just that (needs `curl` and `openssl`):

```sh
curl -fsSL https://raw.githubusercontent.com/jnihal/dotfiles/main/.local/bin/dev-sync -o /tmp/dev-sync
DEV_SYNC_DEST=<dest> bash /tmp/dev-sync restore    # prompts for the passphrase
curl -fsSL https://raw.githubusercontent.com/jnihal/dotfiles/main/.term-init.sh | bash
```

## Managing dotfiles

```sh
dotfile status
dotfile add .zshrc
dotfile commit -m "Update zshrc"
dotfile push
```
