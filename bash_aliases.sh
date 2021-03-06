# Global settings
alias repos='cd ~/code/repos'
alias ll='ls -alhF'
alias tree='tree -C'

# Git
alias rebase='git pull --rebase origin master'
alias master-reset='git checkout -B master origin/master && git pull'
alias purge-merged-branches='git branch --merged | egrep -v "(^\*|master|main|dev)" | xargs git branch -d'
alias gg='git rev-list --all | xargs git --no-pager grep --color=never --extended-regexp --ignore-case'  # usage: gg <regexp>
alias glog='git log --graph --decorate --pretty=oneline --abbrev-commit'

# Docker
alias wrk='docker run --interactive --tty --rm skandyla/wrk'
alias ubuntu='docker run --interactive --tty --rm --volume $(pwd):/host:ro ubuntu:20.04 bash'
alias docker-ip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"  # append container id
alias k9s='docker run --rm -it -v $KUBECONFIG:/root/.kube/config quay.io/derailed/k9s'

# Python
alias pyclean='find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf'
alias pip-purge='pip list --format freeze | xargs pip uninstall -y'
alias pip-install-reqs='ls requirements*.txt | xargs -n 1 pip install -r'
alias poetry-install-master='pipx install --suffix=@master --force git+https://github.com/python-poetry/poetry.git'
alias activate='source .venv/bin/activate'
# assuming pyenv
alias pipx-install='pyenv global 3.9.2 && PIP_REQUIRE_VIRTUALENV=false python -m pip install -U pipx && pyenv global system'
alias pipx='$HOME/.pyenv/versions/3.9.2/bin/pipx'
alias venv='PIP_REQUIRE_VIRTUALENV=false python -m pip install --upgrade --user pip virtualenv && python -m virtualenv .venv && source .venv/bin/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'

# Gerrit
alias gerrit-push='git push origin HEAD:refs/for/master'
alias gerrit-draft='git push origin HEAD:refs/drafts/master'
alias gerrit-amend='git commit --amend'
alias gp='gerrit-amend && gerrit-push'
alias gp-draft='gerrit-amend && gerrit-draft'


# Per-platform settings, will override the above commands
case `uname` in
    Darwin)
        # commands for macOS Big Sur go here

    ;;
    Linux)
        # commands for Linux go here
        if [ -f /etc/redhat-release ]; then
            # vscode fix
            # https://code.visualstudio.com/updates/v1_53#_electron-11-update
            alias code='LD_LIBRARY_PATH=/app/vbuild/RHEL7-x86_64/gcc/9.3.0/lib64/:$LD_LIBRARY_PATH $HOME/apps/vscode/bin/code'
        fi

    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
    MINGW64_NT-*)
        # commands for Git bash in Windows go here

        # Python
        alias activate='source .venv/Scripts/activate'
        # assuming pyenv
        alias venv='PIP_REQUIRE_VIRTUALENV=false python -m pip install --upgrade --user pip virtualenv && python -m virtualenv .venv && source .venv/Scripts/activate && python -m pip install --upgrade pip && which pip && pip list && pip --version && python --version'

    ;;
esac


