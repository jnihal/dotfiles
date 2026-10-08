# dotfiles

Generic dev setup (zsh, oh-my-zsh + powerlevel10k, tmux, vim, git, fzf, iTerm2 settings)
in a bare Git repo with `$HOME` as the work tree. Works on macOS, Linux, VMs and
containers. Nothing work-related is tracked here; see [Work files](#work-files).

## New Mac

Do all of this in **Terminal.app**, not iTerm2. The installer points iTerm2 at the
tracked settings and skips that step while iTerm2 is running.

1. Command line tools (git, compilers):

   ```sh
   xcode-select --install
   ```

2. [Homebrew](https://brew.sh), then put it on `PATH` for this shell (`.zprofile` does
   it permanently later):

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

3. iTerm2 and VS Code (the cask also adds the `code` command):

   ```sh
   brew install --cask iterm2 visual-studio-code
   ```

4. Run the installer (see [Install](#install)). It also points iTerm2 at the settings in
   `~/.config/iterm2-prefs`.

5. Quit Terminal.app and open iTerm2: your profiles, colors and font are loaded.
   On a work Mac, now restore the [work files](#work-files).

## Install

Linux, VMs, containers and step 4 above:

```sh
curl -fsSL https://raw.githubusercontent.com/jnihal/dotfiles/main/.term-init.sh | bash
```

Options go after `bash -s --`: `--chsh` also makes zsh the login shell. `GIT_NAME` and
`GIT_EMAIL` in the environment are written to `~/.gitconfig.local`.

It installs missing packages (brew, apt, apk, dnf, yum or pacman; works as root without
sudo), oh-my-zsh, powerlevel10k, zsh-autosuggestions, fzf and tmux plugins, then checks
out the dotfiles. Files that conflict are moved to `~/.dotfiles-backup`. Re-running is
safe, and optional tools (such as `delta`) are skipped with a warning if the distro
doesn't package them.

- Alpine has no `bash`: run `apk add bash curl` first.
- If packages must come from an internal mirror or proxy, configure that first.

## Per-machine files (untracked)

- `~/.zshrc.local`, `~/.zprofile.local`: extra shell config and environment
- `~/.gitconfig.local`: git identity, URL rewrites, delta pager

## Work files

`dev-sync` (`~/.local/bin/dev-sync`) keeps work-only files out of this repo. It tars the
files listed in `~/.config/dev-sync/manifest` (plus the three `*.local` files above),
encrypts them with AES-256 and a passphrase, and copies the archive to `DEV_SYNC_DEST`
(a directory or `host:dir`).

Set it up once in `~/.config/dev-sync/config`:

```sh
DEV_SYNC_DEST=host:dir                          # or a synced folder
DEV_SYNC_PASSFILE=~/.config/dev-sync/passphrase # chmod 600; only needed for `schedule`
```

```sh
dev-sync backup      # encrypt + upload; keeps the previous archive as .prev
dev-sync restore     # download + decrypt + unpack; overwritten files are saved aside
dev-sync schedule    # daily backup (launchd on macOS, cron elsewhere)
```

On a new machine, run the installer first, then restore. Pass the destination in the
environment, since the config file isn't there yet:

```sh
DEV_SYNC_DEST=<dest> ~/.local/bin/dev-sync restore    # prompts for the passphrase
```

`backup` refuses to replace an existing backup until the machine has restored once, so a
new machine can't overwrite it by accident. Use `backup --force` to override.

## iTerm2 settings

iTerm2 reads and writes `~/.config/iterm2-prefs/com.googlecode.iterm2.plist`, which is
tracked here. Never track `~/.config/iterm2`; that is iTerm2's own state and holds
secrets. To save the settings from a Mac that has them:

1. `mkdir -p ~/.config/iterm2-prefs`
2. iTerm2 → Settings → General → Settings → tick **Load settings from a custom folder
   or URL** and choose that folder. In the file dialog, Cmd+Shift+. shows hidden
   folders and Cmd+Shift+G accepts a typed path.
3. Set **Save changes** to *Automatically*, then click **Save Current Settings to
   Folder** once.
4. Check for private data, then commit:

   ```sh
   grep -i -E 'ssh|@|/Users/|host' ~/.config/iterm2-prefs/com.googlecode.iterm2.plist
   dotfile add ~/.config/iterm2-prefs/com.googlecode.iterm2.plist
   dotfile commit -m "Update iTerm2 settings" && dotfile push
   ```

iTerm2 keeps rewriting the file, so `dotfile status` often shows it modified; commit it
only when a change matters.

## Managing dotfiles

```sh
dotfile status
dotfile add .zshrc
dotfile commit -m "Update zshrc"
dotfile push        # needs an SSH key for GitHub
```
