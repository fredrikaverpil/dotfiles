# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS Big Sur go here
        alias python3.8='python3'  # default
        alias venv3.8='PIP_REQUIRE_VIRTUALENV=false python3.8 -m pip install --upgrade --user pip virtualenv && python3.8 -m virtualenv venv && source venv/bin/activate && pip install --upgrade pip && pip list && which pip && pip --version && python --version'
        alias venv3.9='PIP_REQUIRE_VIRTUALENV=false python3.9 -m pip install --upgrade --user pip virtualenv && python3.9 -m virtualenv venv && source venv/bin/activate && pip install --upgrade pip && pip list && which pip && pip --version && python --version'
        alias activate='source venv/bin/activate'

    ;;
    Linux)
        # commands for Linux go here
        alias venv='PIP_REQUIRE_VIRTUALENV=false python -m pip install --upgrade --user pip virtualenv && python -m virtualenv .venv && source .venv/bin/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias venv3.6='PIP_REQUIRE_VIRTUALENV=false python3.6 -m pip install --upgrade --user pip virtualenv && python3.6 -m virtualenv venv && source venv/bin/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias venv3.7='PIP_REQUIRE_VIRTUALENV=false python3.7 -m pip install --upgrade --user pip virtualenv && python3.7 -m virtualenv venv && source venv/bin/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias venv3.8='PIP_REQUIRE_VIRTUALENV=false python3.8 -m pip install --upgrade --user pip virtualenv && python3.8 -m virtualenv venv && source venv/bin/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias venv3.9='PIP_REQUIRE_VIRTUALENV=false python3.9 -m pip install --upgrade --user pip virtualenv && python3.9 -m virtualenv venv && source venv/bin/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias activate='source venv/bin/activate'
    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
    MINGW64_NT-*)
        # commands for Git bash in Windows go here
        alias python3.6='/c/Users/eavefre/AppData/Local/Programs/Python/Python36/python.exe'
        alias python3.7='/c/Users/eavefre/AppData/Local/Programs/Python/Python37/python.exe'
        alias python3.8='/c/Users/eavefre/AppData/Local/Programs/Python/Python38/python.exe'
        alias python3.9='/c/Users/eavefre/AppData/Local/Programs/Python/Python39/python.exe'
        alias venv3.6='PIP_REQUIRE_VIRTUALENV=false python3.6 -m pip install --upgrade --user pip virtualenv && python3.6 -m virtualenv venv && source venv/Scripts/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias venv3.7='PIP_REQUIRE_VIRTUALENV=false python3.7 -m pip install --upgrade --user pip virtualenv && python3.7 -m virtualenv venv && source venv/Scripts/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias venv3.8='PIP_REQUIRE_VIRTUALENV=false python3.8 -m pip install --upgrade --user pip virtualenv && python3.8 -m virtualenv venv && source venv/Scripts/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias venv3.9='PIP_REQUIRE_VIRTUALENV=false python3.9 -m pip install --upgrade --user pip virtualenv && python3.9 -m virtualenv venv && source venv/Scripts/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias pipx3.6='/c/Users/eavefre/AppData/roaming/python/python36/Scripts/pipx.exe'
        alias pipx3.7='/c/Users/eavefre/AppData/roaming/python/python37/Scripts/pipx.exe'
        alias pipx3.8='/c/Users/eavefre/AppData/roaming/python/python38/Scripts/pipx.exe'
        alias pipx3.9='/c/Users/eavefre/AppData/roaming/python/python39/Scripts/pipx.exe'
        alias activate='source venv/Scripts/activate'

    ;;
esac


# Global settings
alias ll='ls -alhF'
alias tree='tree -C'

alias gg='git grep'
alias rebase='git pull --rebase origin master'
alias master-pull='git checkout master && git pull'
alias branch-delete='git branch --merged | grep -v \* | xargs git branch -D'
alias branch-delete-all='git branch | grep -v \* | xargs git branch -D'
alias master-reset='git checkout -B master origin/master && git pull'

alias wrk='docker run --interactive --tty --rm skandyla/wrk'
alias ubuntu='docker run --interactive --tty --rm --volume $(pwd):/host:ro ubuntu:18.04 bash'
alias docker-ip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"  # append container id
alias k='kubectl'
alias repos='cd ~/code/repos'

alias pyclean='find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf'
alias pip-purge='pip list --format freeze | xargs pip uninstall -y'
alias pip-install-reqs='ls requirements*.txt | xargs -n 1 pip install -r'

# Gerrit
alias gerrit-push='git push origin HEAD:refs/for/master'
alias gerrit-draft='git push origin HEAD:refs/drafts/master'
alias gerrit-amend='git commit --amend'
alias gp='gerrit-amend && gerrit-push'
alias gp-draft='gerrit-amend && gerrit-draft'
