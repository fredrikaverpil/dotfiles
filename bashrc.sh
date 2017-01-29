# Aliases
alias ll='ls -alhF'
alias tree='tree -C'

# Environment variables
export PATH=~/miniconda3/bin:"$PATH"
# export PATH=/opt/local/bin:/opt/local/sbin:${PATH}

if [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
    # Assume Bash

  if [ "$(uname -s)" == "Darwin" ]; then
    # Assume macOS

    # Enable colors
    export CLICOLOR=1

    # Source file if it exists and have a size greater than zero
    [[ -s ~/.bash_prompt ]] && source ~/.bash_prompt
  fi
fi
