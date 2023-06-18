# dotfiles

[![CI](https://github.com/fredrikaverpil/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/fredrikaverpil/dotfiles/actions/workflows/test.yml)

**Introduction**

These are my personal dotfiles, for macOS, Windows and Linux. The setup is based on [dotbot](https://github.com/anishathalye/dotbot) and aims to be as idempotent as possible.

## Install 🚀

- [macOS](README_MACOS.md)
- [Windows 11 + WSL](README_WIN_WSL.md)

### Fonts 💯

- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono)
- [Symbols Nerd Font Mono](https://github.com/ryanoasis/nerd-fonts)
- [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)

### Local secrets 🔐

Use `shell/.env` for local secrets.

### Clone all my public repos 🧔

If more than 100 repos, change `PAGE` variable..

```bash
cd ~/code/repos
USER=fredrikaverpil; PAGE=1; curl "https://api.github.com/users/$USER/repos?page=$PAGE&per_page=100" | grep -e 'git_url*' | cut -d \" -f 4 | xargs -L1 git clone --recursive
```
