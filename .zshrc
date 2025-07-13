# ----------------------------
# oh-my-zsh
# ----------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  zsh-autosuggestions
  git-auto-fetch
)

source $ZSH/oh-my-zsh.sh

# ----------------------------
# path setup
# ----------------------------
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# ----------------------------
# editor
# ----------------------------
export EDITOR=vim

# ----------------------------
# enable starship
# ----------------------------
eval "$(starship init zsh)"

# ----------------------------
# .dotfile alias
# ----------------------------
alias dotfile="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
