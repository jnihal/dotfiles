# dotfiles

This repository contains my personal dotfiles to quickly set up a consistent and productive development environment.

## Features

- Zsh with Oh My Zsh
- Starship prompt configuration
- Git settings
- Shell aliases, exports, and functions
- Managed using a bare Git repository

## Installation

Run this on a new machine:

```sh
curl -fsSL https://raw.githubusercontent.com/jnihal/dotfiles/main/.term-init.sh) | bash
```

This will:

- Install required tools like `zsh`, `git`, and `starship`
- Set Zsh as the default shell
- Clone this repository as a bare Git repo
- Symlink the dotfiles into your home directory

## Tracked Files

- .zshrc
- .gitconfig
- .config/starship.toml
- .aliases
- .exports
- .functions

## Requirements

- Linux or macOS
- curl, git, zsh

## Notes

This setup uses the [bare repository method](https://www.atlassian.com/git/tutorials/dotfiles) to track dotfiles without adding a .git directory to $HOME.

## Managing Dotfiles

Use the following alias to manage your dotfiles:

```sh
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

Example usage:

```sh
dotfiles status
dotfiles add .zshrc
dotfiles commit -m "Update zshrc"
dotfiles push
```
