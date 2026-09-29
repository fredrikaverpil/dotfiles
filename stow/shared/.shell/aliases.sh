# shellcheck shell=bash

# Aliases; runs in the same shell you are already in
# See bin folder for scripts which will run in their own shell

# Global settings
alias dotfiles='cd $DOTFILES'
alias ll='eza --long --header --group-directories-first --git --group --all --color=auto'
alias tree='tree -C'

# Git
alias gs='git status'
alias lg='lazygit'
alias git-purge='git branch --merged | egrep -v "(^\*|master|main|dev)" | xargs git branch -d'
alias git-grep='git rev-list --all | xargs git --no-pager grep --extended-regexp --ignore-case' # usage: gg <regexp>
alias glog='git log --graph --decorate --pretty=oneline --abbrev-commit --all'
alias submodule-reset='git submodule deinit -f . && git submodule update --init --recursive'

# Containers
alias ubuntu='docker run --interactive --tty --rm --volume $(pwd):/host:ro ubuntu:20.04 bash'
alias docker-ip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'" # append container id

# Python
alias pyclean='find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rvf'
alias pip-purge='pip list --format freeze | xargs pip uninstall -y'
alias activate='source .venv/bin/activate'

# Nix
alias dev-toolchain='nix develop ~/.dotfiles#dev --command zsh' # enter the shared dev toolchain shell (nix/shared/toolchain.nix)

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
