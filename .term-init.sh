#!/usr/bin/env bash

set -e

install_package() {
    local pkg="$1"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y "$pkg"
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y "$pkg"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$pkg"
    elif command -v brew >/dev/null 2>&1; then
        brew install "$pkg"
    else
        echo "Could not detect supported package manager to install $pkg"
        return 1
    fi
}

# Install git if not installed
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    install_package git
fi

# Install zsh if not installed
if ! command -v zsh >/dev/null 2>&1; then
    echo "Installing zsh..."
    install_package zsh
fi

# Install zsh if not installed
if ! command -v chsh >/dev/null 2>&1; then
    echo "Installing chsh..."
    install_package util-linux-user
fi

# Change shell to zsh
exec zsh

# Install oh-my-zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "oh-my-zsh already installed."
fi

# Install powerlevel10k theme if not already installed
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    echo "Installing powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo "powerlevel10k theme already installed. Pulling latest changes..."
    git -C "$P10K_DIR" pull
fi

# Install zsh-autosuggestions plugin if not already installed
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo "zsh-autosuggestions already installed. Pulling latest changes..."
    git -C "$ZSH_CUSTOM/plugins/zsh-autosuggestions" pull
fi

# Setup dotfiles using a bare git repository

DOTFILES_REPO="https://github.com/jnihal/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup"

# Clone the bare repository if it doesn't exist
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    echo "Dotfiles repository already cloned. Pulling latest changes..."
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" pull
fi

# Define dotfile function for managing dotfiles
dotfile() {
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Attempt to check out dotfiles
echo "Trying to check out dotfiles..."
if ! dotfile checkout; then
    echo "Backing up pre-existing dotfiles..."

    conflicted_files=$(dotfile checkout 2>&1 | grep -E '^\s+\.' | sed 's/^[[:space:]]*//')

    echo "$conflicted_files" | while read -r file; do
        echo "Backing up $file..."
        mkdir -p "$(dirname "$BACKUP_DIR/$file")"
        mv "$HOME/$file" "$BACKUP_DIR/$file"
    done

    echo "Retrying dotfiles checkout..."
    dotfile checkout
else
    echo "Checked out dotfiles from $DOTFILES_REPO"
fi

# Hide untracked files from dotfile status
dotfile config status.showUntrackedFiles no

# Install fzf (fuzzy finder) if not already installed
if [ ! -d "$HOME/.fzf" ]; then
    echo "Installing fzf (fuzzy finder)..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --key-bindings --completion --no-update-rc
else
    echo "fzf already installed. Pulling latest changes..."
    git -C ~/.fzf pull
    ~/.fzf/install --key-bindings --completion --no-update-rc
fi

# Source zshrc
source ~/.zshrc

# Change default shell to zsh
echo "Changing shell to zsh..."
sudo chsh -s "$(which zsh)" "$USER" || echo "chsh failed. Please run 'sudo chsh -s $(which zsh) \"$USER\"' to change shell."
