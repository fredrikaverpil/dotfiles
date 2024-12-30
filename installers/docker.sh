#!/bin/bash -ex

# https://docs.docker.com/engine/install

# Per-platform settings
case $(uname) in
Darwin)
	# commands for macOS go here
	echo "Install via Docker Desktop manual download on macOS."

	;;
Linux)
	# commands for Linux go here
	if ! command -v docker &>/dev/null; then
		if command -v apt-get &>/dev/null; then
			sudo apt-get update
			sudo apt-get -y install \
				apt-transport-https \
				ca-certificates \
				curl \
				gnupg \
				lsb-release

			# add docker's official gpg key
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

			# setup stable repo
			echo \
				"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

			# install docker engine
			sudo apt-get update
			sudo apt-get install -y docker-ce docker-ce-cli containerd.io

			# add current user to docker group
			sudo usermod -aG docker "${USER}"

			# install docker-compose
			sudo apt-get -y install docker-compose
		fi
	fi

	;;
FreeBSD)
	# commands for FreeBSD go here
	;;
MINGW64_NT-*)
	# commands for Git bash in Windows go here
	;;
*) ;;
esac
