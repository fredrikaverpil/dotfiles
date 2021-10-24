# dotfiles 🐚

[![CI](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml/badge.svg)](https://github.com/fredrikaverpil/dotfiles/actions/workflows/build.yml)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Windows 11 + WSL/Ubuntu](#windows-11--wslubuntu)
- [Ubuntu 20.04](#ubuntu-2004)
  - [Install dotfiles](#install-dotfiles)
  - [Optional installation](#optional-installation)
- [To do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Windows 11 + WSL/Ubuntu

This setup aims to run GUIs in Windows with all terminal and coding activities in WSL/Ubuntu.

See [_windows/README.md](_windows/README.md) for setup instructions.

## Ubuntu 20.04

```bash
sudo apt update
sudo apt upgrade
sudo apt install git
```

### Install dotfiles

```bash
mkdir -p code/repos && cd code/repos
git clone https://github.com/fredrikaverpil/dotfiles.git
cd dotfiles && ./install -vv
```

### Optional installation

```bash
installers/python.sh
installers/docker.sh  # only if Docker Desktop in Windows was not installed
installers/snap-apps.sh
installers/nix.sh
installers/homebrew.sh  # experimental!
installers/zsh.sh  # edit out the default prompt from ~/.zshrc after installation
```

## To do

* improve this README (add note on setup being idempotent)
* bring back details from old README
* move macOS setup into dotbot.
