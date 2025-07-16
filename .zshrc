# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  zsh-autosuggestions
  git-auto-fetch
)

source $ZSH/oh-my-zsh.sh
export TERM=xterm-256color

# path setup
export PATH="$HOME/.fzf/bin:$HOME/bin:/usr/local/bin:$PATH"

# editor
export EDITOR=vim

# dotfile alias
alias dotfile="git --git-dir=$HOME/.dotfiles --work-tree=$HOME"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# setup fzf
source <(fzf --zsh)
