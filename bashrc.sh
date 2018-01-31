# Aliases
alias ll='ls -alhF'
alias tree='tree -C'

# Environment variables
export PATH="$PATH:~/miniconda3/bin"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export CONDAENVS=~/miniconda3/envs

# Per-platform specifics
if [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
    # Assume Bash

  if [ "$(uname -s)" == "Darwin" ]; then
    # Assume macOS

    # Enable colors
    export CLICOLOR=1

  fi

  # Source file if it exists and have a size greater than zero
  [[ -s ~/.bash_prompt ]] && source ~/.bash_prompt

fi
