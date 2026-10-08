#!/usr/bin/env bash
# Bootstrap my generic dev environment on macOS, Linux, VMs and containers.
# Safe to re-run. Nothing work-specific lives here; see ~/.local/bin/dev-sync.
#
#   curl -fsSL https://raw.githubusercontent.com/jnihal/dotfiles/main/.term-init.sh | bash
#   curl -fsSL .../.term-init.sh | bash -s -- --chsh     # also make zsh the login shell
#
# Optional environment: GIT_NAME, GIT_EMAIL (written to ~/.gitconfig.local).
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/jnihal/dotfiles.git}"
DOTFILES_PUSH_URL="git@github.com:jnihal/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup"
ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH_DIR/custom"

SET_SHELL=0
for arg in "$@"; do
    case "$arg" in
        --chsh) SET_SHELL=1 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- packages --

# Containers usually run as root without sudo; elsewhere we need sudo.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if have sudo; then SUDO=sudo; else SUDO=none; fi
fi
as_root() {
    if [ "$SUDO" = none ]; then return 1; fi
    $SUDO "$@"
}

PM=""
if   have brew;    then PM=brew
elif have apt-get; then PM=apt
elif have apk;     then PM=apk
elif have dnf;     then PM=dnf
elif have yum;     then PM=yum
elif have pacman;  then PM=pacman
fi

# Generic command name -> package name for the detected package manager.
pkg_name() {
    case "$PM:$1" in
        apt:ssh|apk:ssh)        echo openssh-client ;;
        dnf:ssh|yum:ssh)        echo openssh-clients ;;
        pacman:ssh)             echo openssh ;;
        brew:ssh)               echo "" ;;               # ships with macOS
        apk:delta)              echo delta ;;
        *:delta)                echo git-delta ;;
        *)                      echo "$1" ;;
    esac
}

pm_install() {
    case "$PM" in
        brew)   brew install "$@" ;;
        apt)    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" ;;
        apk)    as_root apk add --no-cache "$@" ;;
        dnf)    as_root dnf install -y "$@" ;;
        yum)    as_root yum install -y "$@" ;;
        pacman) as_root pacman -S --noconfirm --needed "$@" ;;
        *)      return 1 ;;
    esac
}

# ensure required|optional <command>...   (installs whatever is missing)
ensure() {
    local need=$1 c pkg missing=()
    shift
    for c in "$@"; do
        if ! have "$c"; then
            pkg=$(pkg_name "$c")
            if [ -n "$pkg" ]; then missing+=("$pkg"); fi
        fi
    done
    if [ ${#missing[@]} -eq 0 ]; then return 0; fi

    log "Installing ${missing[*]}"
    if [ "$PM" = apt ]; then as_root apt-get update -qq || warn "apt-get update failed"; fi

    if [ "$need" = required ]; then
        if [ "$PM" != brew ]; then missing+=(ca-certificates); fi
        pm_install "${missing[@]}" || die "could not install: ${missing[*]} (no package manager, or no root/sudo)"
    else
        for pkg in "${missing[@]}"; do
            pm_install "$pkg" || warn "optional package not installed: $pkg"
        done
    fi
}

if [ -z "$PM" ]; then
    warn "no supported package manager found (on macOS install Homebrew first: https://brew.sh)"
fi

ensure required git zsh curl bash
ensure optional tmux vim openssl rsync ssh delta
have git && have zsh && have curl || die "git, zsh and curl are required"

# ------------------------------------------------------------- shell setup --

# clone_or_update <url> <dir>
clone_or_update() {
    if [ -d "$2/.git" ]; then
        git -C "$2" pull --ff-only -q || warn "could not update $2"
    else
        git clone --depth 1 -q "$1" "$2"
    fi
}

log "oh-my-zsh, powerlevel10k, plugins"
clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
mkdir -p "$ZSH_CUSTOM/themes" "$ZSH_CUSTOM/plugins"
clone_or_update https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

# Use ~/.fzf unless a system fzf is already there (.zshrc needs fzf >= 0.48 for `fzf --zsh`).
if [ -d "$HOME/.fzf" ] || ! have fzf; then
    log "fzf"
    clone_or_update https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --bin >/dev/null || warn "fzf binary install failed"
fi

# ---------------------------------------------------------------- dotfiles --
# Bare repository in ~/.dotfiles with $HOME as the work tree.

dotfile() { git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"; }

if [ ! -d "$DOTFILES_DIR" ]; then
    log "Cloning dotfiles"
    git clone --bare -q "$DOTFILES_REPO" "$DOTFILES_DIR"
    dotfile remote set-url --push origin "$DOTFILES_PUSH_URL"
else
    log "Updating dotfiles"
    dotfile pull --ff-only -q origin "$(dotfile symbolic-ref --short HEAD)" \
        || warn "could not fast-forward dotfiles (local changes?)"
fi

if ! dotfile checkout >/dev/null 2>&1; then
    log "Moving conflicting files to $BACKUP_DIR"
    # git lists the files it would overwrite, one per indented line
    conflicts=$(dotfile checkout 2>&1 | grep -E '^[[:space:]]+[^[:space:]]' | sed 's/^[[:space:]]*//' || true)
    [ -n "$conflicts" ] || die "dotfiles checkout failed: $(dotfile checkout 2>&1 | head -3)"
    while IFS= read -r file; do
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        mv "$HOME/$file" "$BACKUP_DIR/$file"
    done <<< "$conflicts"
    dotfile checkout
fi
dotfile config status.showUntrackedFiles no

# ------------------------------------------------------------ tmux plugins --

if have tmux; then
    log "tmux plugins"
    clone_or_update https://github.com/tmux-plugins/tpm.git "$HOME/.tmux/plugins/tpm"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || warn "tmux plugin install failed (run prefix + I inside tmux)"
fi

# -------------------------------------------------------------- git (local) --
# Identity and optional features live in ~/.gitconfig.local, which is never tracked.

LOCAL_GIT="$HOME/.gitconfig.local"
if [ -n "${GIT_NAME:-}" ];  then git config -f "$LOCAL_GIT" user.name  "$GIT_NAME"; fi
if [ -n "${GIT_EMAIL:-}" ]; then git config -f "$LOCAL_GIT" user.email "$GIT_EMAIL"; fi
if have delta && ! git config -f "$LOCAL_GIT" --get core.pager >/dev/null 2>&1; then
    git config -f "$LOCAL_GIT" core.pager delta
    git config -f "$LOCAL_GIT" interactive.diffFilter "delta --color-only"
fi

# ------------------------------------------------------------ login shell --

if [ "$SET_SHELL" -eq 1 ]; then
    zsh_path=$(command -v zsh)
    if chsh -s "$zsh_path" 2>/dev/null || as_root chsh -s "$zsh_path" "$USER" 2>/dev/null; then
        log "Login shell set to $zsh_path"
    else
        warn "could not change login shell; run: chsh -s $zsh_path"
    fi
fi

cat <<EOF

Done. Start a new shell with: exec zsh
EOF
if [ -z "$(git config --get user.email || true)" ]; then
    echo "Git identity not set: git config -f ~/.gitconfig.local user.name 'Your Name'; git config -f ~/.gitconfig.local user.email you@example.com"
fi
echo "On a work machine, restore the work-only files with: DEV_SYNC_DEST=<dest> ~/.local/bin/dev-sync restore"
