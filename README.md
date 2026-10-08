# dotfiles

Generic dev setup (zsh, oh-my-zsh + powerlevel10k, tmux, vim, git, fzf) kept in a
bare Git repo with `$HOME` as the work tree. Works on macOS, Linux, VMs and containers.
Nothing work-related is tracked here; see **Work files** below.

## macOS setup (new Mac, do this first)

1. Install the Xcode command line tools (provides `git`, `make`, compilers):

   ```sh
   xcode-select --install
   ```

2. Install [Homebrew](https://brew.sh):

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   On Apple Silicon `brew` lives in `/opt/homebrew`, which isn't on `PATH` yet. Put it
   there for the current shell (the dotfiles' `.zprofile` does this permanently later):

   ```sh
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

3. Install iTerm2 and VS Code:

   ```sh
   brew install --cask iterm2 visual-studio-code
   ```

   The VS Code cask also puts the `code` command on your `PATH`.

4. Restore the iTerm2 settings (profiles, colors, font, keybindings) once the dotfiles
   are checked out, see **iTerm2 settings** below. The font is part of those settings;
   nothing here changes it.

5. Continue with **Install** below. `.term-init.sh` uses Homebrew to install anything
   still missing (tmux, vim, delta, ...). Then open a new iTerm2 window (or run
   `exec zsh`); `p10k configure` re-runs the prompt wizard if you want to change it.

## iTerm2 settings

iTerm2 reads and writes its settings from `~/.config/iterm2-prefs/` (tracked in this
repo). Do not track `~/.config/iterm2`; that is iTerm2's own state and holds secrets.

Save (on the Mac that has the settings you want):

1. iTerm2 → Settings → General → Settings.
2. Tick **Load settings from a custom folder or URL** and choose `~/.config/iterm2-prefs`
   (create it first with `mkdir -p ~/.config/iterm2-prefs`).
3. Set **Save changes** to *Automatically* (or *When quitting*), then click **Save
   Current Settings to Folder** once.
4. Check the file for anything private, then commit it:

   ```sh
   grep -i -E 'ssh|@|/Users/|host' ~/.config/iterm2-prefs/com.googlecode.iterm2.plist
   dotfile add ~/.config/iterm2-prefs/com.googlecode.iterm2.plist
   dotfile commit -m "Update iTerm2 settings" && dotfile push
   ```

   Later changes are written to the file automatically; commit it again when you want
   to keep them.

Restore (new Mac): `.term-init.sh` does this for you; quit and reopen iTerm2 afterwards.
By hand (with iTerm2 quit), after checking out the dotfiles:

```sh
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.config/iterm2-prefs"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
```

and open iTerm2.

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

On a new work machine or container, run the install script first, then restore the work
files. If the machine can only reach package mirrors through a proxy or internal mirror,
configure that *before* running the install script, since the script itself installs
packages. `dev-sync` is a single file, so you can also fetch just that (needs `curl` and
`openssl`):

```sh
curl -fsSL https://raw.githubusercontent.com/jnihal/dotfiles/main/.term-init.sh | bash
DEV_SYNC_DEST=<dest> ~/.local/bin/dev-sync restore    # prompts for the passphrase

# or, without the dotfiles:
curl -fsSL https://raw.githubusercontent.com/jnihal/dotfiles/main/.local/bin/dev-sync -o /tmp/dev-sync
DEV_SYNC_DEST=<dest> bash /tmp/dev-sync restore
```

## Managing dotfiles

```sh
dotfile status
dotfile add .zshrc
dotfile commit -m "Update zshrc"
dotfile push
```
