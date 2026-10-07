# Login-shell environment. Generic only; work/machine specifics go in ~/.zprofile.local.
typeset -U path PATH   # keep PATH free of duplicates

# Homebrew (macOS or Linuxbrew)
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x $_brew ]]; then eval "$($_brew shellenv)"; break; fi
done
unset _brew

# GNU userland ahead of the BSD tools on macOS
if [[ $OSTYPE == darwin* && -n ${HOMEBREW_PREFIX:-} ]]; then
  for _p in util-linux/bin util-linux/sbin make/libexec/gnubin findutils/libexec/gnubin gnu-sed/libexec/gnubin; do
    [[ -d $HOMEBREW_PREFIX/opt/$_p ]] && path=("$HOMEBREW_PREFIX/opt/$_p" $path)
  done
  unset _p
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && path=("$PYENV_ROOT/bin" $path)
(( $+commands[pyenv] )) && eval "$(pyenv init -)"

# user bin directories
for _p in "$HOME/.fzf/bin" "$HOME/bin" "$HOME/go/bin" "$HOME/.local/bin"; do
  [[ -d $_p ]] && path=("$_p" $path)
done
unset _p

[[ -r ~/.zprofile.local ]] && source ~/.zprofile.local
