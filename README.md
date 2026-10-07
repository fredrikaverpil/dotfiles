# dotfiles 🍩

![screenshot](https://github.com/user-attachments/assets/d8b0b742-a77c-4e55-94b6-3640723739e2)

Personal dotfiles, managed in three layers:

- **Nix** ([`nix/`](nix/)) — system configuration and packages,
  pinned by `flake.lock` and applied with a rebuild. Fully reproducible.
- **Stow** ([`stow/`](stow/)) — dotfiles symlinked into `$HOME` with
  [GNU Stow](https://www.gnu.org/software/stow/) (not Nix). Changes take effect
  immediately, no rebuild needed.
- **Homebrew** (macOS) — GUI apps and Mac App Store apps. Nix declares _which_
  packages and a rebuild installs or removes to match, but versions are
  unpinned and upgraded manually.

The Linux desktop experience is [kaizen](docs/kaizen/README.md) (a homegrown
combination of NixOS, niri and Quickshell).

## Quickstart

1. Install either...\
   a. NixOS\
   b. macOS + Homebrew + nix-darwin
2. Clone this repo into `~/.dotfiles`
3. Make sure `hostname` is set and run:

   ```sh
   sudo nixos-rebuild switch --flake ~/.dotfiles#"$(hostname -s)"   # NixOS
   sudo darwin-rebuild switch --flake ~/.dotfiles#"$(hostname -s)"  # macOS
   ```

Then, after the first rebuild, some common commands:

```sh
# rebuild and switch using nh
nh os switch --ask  # NixOS
nh darwin switch --ask  # macOS

# run stowing of files
dotfiles-stow

# update all flake inputs
nix flake update

# update only specific input
nix flake update llm-agents  # example

# clean up old generations
sudo nix-collect-garbage --delete-older-than 5d

# update homebrew packages on macOS
brew update && brew upgrade   # add --greedy to also bump self-updating casks
```

> [!NOTE]
>
> Pinning Homebrew versions is possible via
> [nix-homebrew](https://github.com/zhaofengli/nix-homebrew) with locked taps,
> but it buys little here: casks that self-update ignore the pin, vendors delete
> old cask artifacts, and Mac App Store apps cannot be pinned at all.

## Convenience links

- Neovim ⌨️
  - [My config](stow/shared/.config/nvim-fredrik/)
  - [Minimalistic config](stow/shared/.config/nvim-simple/) - for when a full
    blown IDE is too much; inspired by
    [NativeVim](https://github.com/boltlessengineer/NativeVim) and
    [Sylvan Franklin's config](https://github.com/SylvanFranklin/.config/tree/main/nvim)
- Workflows 🌊
  - [Git config](extras/README_GIT.md)
  - [Project config](extras/README_PROJECT.md)
  - [Claude Code setup](stow/shared/.claude/)
- Styling 🎨
  - [Zenbones](https://github.com/zenbones-theme/zenbones.nvim)
  - [Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono)
  - [Maple Mono](https://github.com/subframe7536/maple-font)
  - [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)
  - [Symbols Nerd Font Mono](https://github.com/ryanoasis/nerd-fonts)

Agent Club demo!
