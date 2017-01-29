# Get the Git branch
function parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# --> Command execution time // start
function timer_start {
  timer=${timer:-$SECONDS}
}

function timer_stop {
  timer_show=$(($SECONDS - $timer))
  unset timer
}

trap 'timer_start' DEBUG

if [ "$PROMPT_COMMAND" == "" ]; then
  PROMPT_COMMAND="timer_stop"
else
  PROMPT_COMMAND="$PROMPT_COMMAND; timer_stop"
fi
# PS1='[last: ${timer_show}s][\w]$ '

# Command execution time // end <--



if [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
    # Assume Bash

  if [ "$(uname -s)" == "Darwin" ]; then
    # Assume macOS

    # Taken from http://apple.stackexchange.com/questions/33677/how-can-i-configure-mac-terminal-to-have-color-ls-output
    # Enable colors
    export CLICOLOR=1
    # BSD colors
    # export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

    # To do, add command execution time:
    # http://jakemccrary.com/blog/2015/05/03/put-the-last-commands-run-time-in-your-bash-prompt/

    # Custom bash prompt
    # Includes custom character for the prompt, path, and Git branch name.
    # Source: kirsle.net/wizards/ps1.html
    export PS1="\n\[$(tput bold)\]\[$(tput setaf 5)\]➜ \[$(tput setaf 6)\]\w\[$(tput setaf 3)\]\$(parse_git_branch) \[$(tput sgr0)\]"


  fi
fi


# Aliases
alias ll='ls -alhF'

# Environment variables
export PATH=~/miniconda3/bin:"$PATH"
export HOMEBREW_GITHUB_API_TOKEN=5b9a0b98211c32a7015287ce0d64ab3fe55cd07a
# export PATH=/opt/local/bin:/opt/local/sbin:${PATH}
