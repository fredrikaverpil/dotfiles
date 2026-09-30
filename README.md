# dotfiles 🍩

![screenshot](https://github.com/user-attachments/assets/51c05d03-d997-40dc-8757-4d13993fcafb)

Personal dotfiles, managed in three layers:

- **Nix** ([`nix/`](nix/)) — system configuration and packages,
  pinned by `flake.lock` and applied with a rebuild. Fully reproducible.
- **Stow** ([`stow/`](stow/)) — dotfiles symlinked into `$HOME` with
  [GNU Stow](https://www.gnu.org/software/stow/) (not Nix). Changes take effect
  immediately, no rebuild needed.
- **Homebrew** (macOS) — GUI apps and Mac App Store apps. Nix declares _which_
  packages and a rebuild installs or removes to match, but versions are
  unpinned and upgraded manually.

The Linux desktop experience is [kaizen](KAIZEN.md) (a homegrown combination
of NixOS, niri and Quickshell).

## Quickstart

1. Install either...\
   a. NixOS\
   b. macOS + Homebrew + nix
2. Clone this repo into `~/.dotfiles`
3. Make sure `hostname` is set and run:

   ```sh
   sudo nixos-rebuild switch --flake ~/.dotfiles#"$(hostname -s)"   # NixOS
   sudo darwin-rebuild switch --flake ~/.dotfiles#"$(hostname -s)"  # macOS
   ```

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
- Fonts
  - [Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono) ❤️
  - [Maple Mono](https://github.com/subframe7536/maple-font)
  - [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)
  - [Symbols Nerd Font Mono](https://github.com/ryanoasis/nerd-fonts)
