# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here
        alias venv='python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip && pip list && which pip && pip --version && python --version'
        alias activate='source venv/bin/activate'

    ;;
    Linux)
        # commands for Linux go here
    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
    MINGW64_NT-*)
        # commands for Git bash in Windows go here
        alias python3='/c/Users/eavefre/AppData/Local/Programs/Python/Python37/python.exe'
        alias venv='python3 -m venv venv && source venv/Scripts/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias activate='source venv/Scripts/activate'

    ;;
esac


# Global settings
alias ll='ls -alhF'
alias tree='tree -C'
alias gg='git grep'
alias rebase='git pull --rebase origin master'
alias wrk='docker run --interactive --tty --rm skandyla/wrk'
alias ubuntu='docker run --interactive --tty --rm --volume $(pwd):/host:ro ubuntu:18.04 bash'
alias docker-ip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"  # append container id
alias k='kubectl'
alias repos='cd ~/code/repos'

alias pyclean='find . -name "*.py[co]" -o -name __pycache__ -exec rm -rf {}'
alias pip-purge='pip freeze | xargs pip uninstall -y'

alias gerrit-push='git push origin HEAD:refs/for/master'
alias gerrit-amend='git commit --amend'