# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here
        alias venv='python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip && pip list && which pip && pip --version && python --version'
        alias activate='source venv/bin/activate'

    ;;
    Linux)
        # commands for Linux go here
        alias venv='python3 -m venv venv && source venv/bin/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'
        alias activate='source venv/bin/activate'
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
alias master-pull='git checkout master && git pull'
alias branch-delete='git branch --merged | grep -v \* | xargs git branch -D'
alias branch-delete-all='git branch | grep -v \* | xargs git branch -D'

alias wrk='docker run --interactive --tty --rm skandyla/wrk'
alias ubuntu='docker run --interactive --tty --rm --volume $(pwd):/host:ro ubuntu:18.04 bash'
alias docker-ip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"  # append container id
alias k='kubectl'
alias repos='cd ~/code/repos'

alias pyclean='find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf'
alias pip-purge='pip freeze | xargs pip uninstall -y'
alias pip-install-reqs='ls requirements*.txt | xargs -n 1 pip install -r'

alias gerrit-push='git push origin HEAD:refs/for/master'
alias gerrit-amend='git commit --amend'