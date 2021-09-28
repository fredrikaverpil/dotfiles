# dotfiles 🐚

## Prerequisites

### Ubuntu

```bash
sudo apt update
sudo apt upgrade
sudo apt install git
```

## Installation

```bash
git clone https://github.com/fredrikaverpil/dotfiles.git
./install -vv
```

## Optional installation

### Ubuntu

```bash
installers/docker.sh
installers/snap-apps.sh
installers/homebrew.sh  # experimental!

pipx-install  # defined in shell/aliases.sh
pipx install docker-compose
```

## To do

* improve this README (add note on setup being idempotent)
* bring back details from old README
* move macOS setup into dotbot.
