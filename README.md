# dotfiles 🐚

[![CI](https://github.com/fredrikaverpil/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/fredrikaverpil/dotfiles/actions/workflows/test.yml)

**Introduction**

These are my personal dotfiles, for macOS, Windows and Linux. The setup is based on [dotbot](https://github.com/anishathalye/dotbot) and aims to be as idempotent as possible.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [macOS](#macos)
  - [Install dotfiles](#install-dotfiles)
  - [Optional installation](#optional-installation)
  - [Configuration](#configuration)
- [Windows 11 + WSL/Ubuntu](#windows-11--wslubuntu)
  - [Windows installations](#windows-installations)
  - [WSL/Ubuntu installations](#wslubuntu-installations)
  - [Configuration](#configuration-1)
    - [Windows Terminal settings](#windows-terminal-settings)
    - [WSL Tray](#wsl-tray)
    - [Set up HHKB for macOS-compatible workflow](#set-up-hhkb-for-macos-compatible-workflow)
  - [Closing notes](#closing-notes)
- [Ubuntu 20.04](#ubuntu-2004)
  - [Prerequisites](#prerequisites)
  - [Install dotfiles](#install-dotfiles-1)
  - [Optional installation](#optional-installation-1)
- [Extras](#extras)
  - [Local secrets](#local-secrets)
  - [Clone all my public repos](#clone-all-my-public-repos)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Install

- [macOS](README_MACOS.md)
- [Windows 11 + WSL](README_WIN_WSL.md)

### Fonts

- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono)
- [Symbols Nerd Font Mono](https://github.com/ryanoasis/nerd-fonts)
- [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)

### Local secrets

See `shell/.env` for local secrets.

### Clone all my public repos

If more than 100 repos, change `PAGE` variable..

```bash
cd ~/code/repos
USER=fredrikaverpil; PAGE=1; curl "https://api.github.com/users/$USER/repos?page=$PAGE&per_page=100" | grep -e 'git_url*' | cut -d \" -f 4 | xargs -L1 git clone --recursive
```
