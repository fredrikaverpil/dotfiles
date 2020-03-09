# # Simple timers
#
# function timer_start {
#     timer=${timer:-$SECONDS}
# }
#
# function timer_stop {
#   # Simple timer_stop
#     timer_show=$(($SECONDS - $timer))
#     unset timer
# }

echo "in prompt!"

# Advanced timer
function timer_now {
    case `uname` in
        Darwin)
            # Requires 'brew install coreutils' on macOS
            /usr/local/opt/coreutils/libexec/gnubin/date +%s%N
        ;;
        Linux)
            date +%s%N
        ;;
        FreeBSD)
            # commands for FreeBSD go here
        ;;
    esac
}

function timer_start {
    timer_start=${timer_start:-$(timer_now)}
}

function timer_stop {
    local delta_us=$((($(timer_now) - $timer_start) / 1000))
    local us=$((delta_us % 1000))
    local ms=$(((delta_us / 1000) % 1000))
    local s=$(((delta_us / 1000000) % 60))
    local m=$(((delta_us / 60000000) % 60))
    local h=$((delta_us / 3600000000))
    # Goal: always show around 3 digits of accuracy
    if ((h > 0)); then timer_show=${h}h${m}m
    elif ((m > 0)); then timer_show=${m}m${s}s
    elif ((s >= 10)); then timer_show=${s}.$((ms / 100))s
    elif ((s > 0)); then timer_show=${s}.$(printf %03d $ms)s
    elif ((ms >= 100)); then timer_show=${ms}ms
    elif ((ms > 0)); then timer_show=${ms}.$((us / 100))ms
    else timer_show=${us}us
    fi
    unset timer_start
}

function parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Display virtual environment info
function virtualenv_prompt {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    virtualenv=`basename "$VIRTUAL_ENV"`
    echo -e "\n($virtualenv)"
  fi
}


set_prompt () {
    Last_Command=$? # Must come first!
    Blue='\[\e[01;34m\]'
    White='\[\e[01;37m\]'
    Red='\[\e[01;31m\]'
    Green='\[\e[01;32m\]'
    Yellow='$(tput setaf 3)\]'
    Gray='\[\e[01;222m\]'
    Reset='\[\e[00m\]'
    FancyX='\342\234\227'
    Checkmark='\342\234\223'
    PS1=""

    # Show Python virtual environment
    PS1+="$Gray\$(virtualenv_prompt) "

    # Add a bright white exit status for the last command
    PS1+="\n$White\$? "

    # If it was successful, print a green check mark. Otherwise, print
    # a red X.
    if [[ $Last_Command == 0 ]]; then
        PS1+="$Green$Checkmark "
    else
        PS1+="$Red$FancyX "
        tput bel  # Ring the bell
    fi

    # Add the ellapsed time and current date
    timer_stop
    # PS1+="$Reset($timer_show) \t \n"  # with time
    PS1+="$Reset($timer_show) \n"  # without time


    # If root, just print the host in red. Otherwise, print the current user
    # and host in green.
    if [[ $EUID == 0 ]]; then
        PS1+="$Red\\u$Green@\\h "
    else
        PS1+="$Green\\u@\\h "
    fi

    # Print the FULL working directory path
    PS1+="$Blue\\w"

    # Print the working directory name
    # PS1+="$Blue\\W"


    # Print the git branch
    if [[ ! -z $(parse_git_branch) ]]; then
        PS1+="$Yellow$(parse_git_branch)"
    fi

    # Reset the prompt marker text color to the default.
    # PS1+=" $Blue\\\$$Reset "

    # Reset the prompt marker text color to the default (with newline).
    PS1+=" $Blue\n\\\$$Reset "
}

trap 'timer_start' DEBUG
PROMPT_COMMAND='set_prompt'
