# shellcheck shell=bash

# Aliases; runs in the same shell you are already in
# See bin folder for scripts which will run in their own shell

# Global settings
alias dotfiles='cd ~/code/dotfiles'
# alias ll='ls -alhF'
alias ll='eza --long --header --group-directories-first --git --group --all'
alias tree='tree -C'

# Kitty
if command -v kitty &>/dev/null; then
	alias icat='kitty +kitten icat'
	alias diff='kitty +kitten diff'
fi

# Git
alias git-purge='git branch --merged | egrep -v "(^\*|master|main|dev)" | xargs git branch -d'
alias git-grep='git rev-list --all | xargs git --no-pager grep --extended-regexp --ignore-case' # usage: gg <regexp>
alias glog='git log --graph --decorate --pretty=oneline --abbrev-commit --all'
alias submodule-reset='git submodule deinit -f . && git submodule update --init --recursive'

# Docker
alias wrk='docker run --interactive --tty --rm skandyla/wrk'
alias ubuntu='docker run --interactive --tty --rm --volume $(pwd):/host:ro ubuntu:20.04 bash'
alias docker-ip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'" # append container id
# alias k9s='docker run --rm -it -v $KUBECONFIG:/root/.kube/config quay.io/derailed/k9s'

# Python
alias pyclean='find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rvf'
alias pip-purge='pip list --format freeze | xargs pip uninstall -y'
alias pip-install-reqs='ls requirements*.txt | xargs -n 1 pip install -r'
alias poetry-install-master='pipx install --suffix=@master --force git+https://github.com/python-poetry/poetry.git'
alias activate='source .venv/bin/activate'
# assuming pyenv
alias venv='PIP_REQUIRE_VIRTUALENV=false python3 -m pip install --upgrade --user pip virtualenv && python3 -m virtualenv .venv && source .venv/bin/activate && python3 -m pip install --upgrade pip && which pip && pip list && pip --version && python3 --version'

# Neovim
alias nvim-lazy='NVIM_APPNAME=LazyVim nvim'
alias nvim='nvim-lazy'

# GitHub Copilot X
# Sets up aliases for `??`, `git?`, and `gh?`
if which github-copilot-cli >/dev/null; then
	eval "$(github-copilot-cli alias -- "$0")"
fi

# Gerrit
# alias gerrit-push='git push origin HEAD:refs/for/master'
# alias gerrit-draft='git push origin HEAD:refs/drafts/master'
# alias gerrit-amend='git commit --amend'
# alias gp='gerrit-amend && gerrit-push'
# alias gp-draft='gerrit-amend && gerrit-draft'

# Per-platform settings, will override the above commands
case $(uname) in
Darwin)
	# commands for macOS go here
	;;
Linux)
	# commands for Linux go here
	alias bat='batcat'
	;;
esac
