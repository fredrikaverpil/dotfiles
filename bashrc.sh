# Aliases
alias ll='ls -alhF'
alias tree='tree -C'
alias wrk='docker run --rm skandyla/wrk'
alias venv='echo "venv" >> .gitignore && python3 -m venv --copies venv && source venv/bin/activate && pip install -U pip pylint black pep8 pydocstyle && pip list && python --version'
alias activate='source venv/bin/activate'

# Per-platform specifics
if [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
    # Assume Bash

  if [ "$(uname -s)" == "Darwin" ]; then
    # Assume macOS

    # Environment variables
    # export PATH="$PATH:~/miniconda3/bin"
    export HOMEBREW_NO_ANALYTICS=1
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    export PATH="$PATH:$HOME/.cargo/bin"  # Rust


    # Enable colors
    export CLICOLOR=1

  fi

  # Source file if it exists and have a size greater than zero
  [[ -s ~/.bash_prompt ]] && source ~/.bash_prompt

fi
