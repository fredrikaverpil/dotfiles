#!/bin/bash -ex

# NOTE: this script is really just meant to show the setup, not to be run as-is.

function setup_podman() {
	# install podman
	brew install podman

	# install and start podman VM
	# NOTE: commands assume default machine name 'podman-machine-default'
	podman machine init
	podman start

	# install podman-mac-helper which takes care of
	# setting up the docker-like socket etc.
	sudo $HOMEBREW_PREFIX/bin/podman-mac-helper install
	podman machine stop
	podman machine start

	# install podman desktop (optional)
	brew install podman-deskop

	# install podman compose (optional)
	brew install podman-compose

	# set up for ryuk testcontainers
	# You need to add a file ~/.testcontainers.properties with contents:
	touch ~/.testcontainers.properties
	# ryuk.container.privileged = true
	echo "ryuk.container.privileged = true" >~/.testcontainers.properties
}

function reset_podman() {
	rm -rf ~/.colima
	rm -rf ~/.docker

	podman system prune --all --volumes --force
	podman machine stop
	podman machine rm

	sudo $HOMEBREW_PREFIX/bin/podman-mac-helper uninstall
}
