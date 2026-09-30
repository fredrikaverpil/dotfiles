# dotfiles 🍩

![screenshot](https://github.com/user-attachments/assets/51c05d03-d997-40dc-8757-4d13993fcafb)

Personal dotfiles, managed in three layers:

- **Nix** (`nix/`) — system configuration and packages,
  pinned by `flake.lock` and applied with a rebuild. Fully reproducible.
- **Stow** (`stow/`) — dotfiles symlinked into `$HOME` with
  [GNU Stow](https://www.gnu.org/software/stow/) (not Nix). Changes take effect
  immediately, no rebuild needed.
- **Homebrew** (macOS) — GUI apps and Mac App Store apps. Nix declares _which_
  packages and a rebuild installs or removes to match, but versions are
  unpinned and upgraded manually.

The Linux desktop experience is the [kaizen](KAIZEN.md) (a homegrown combination
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

### Nix

```sh
# rebuild/switch after initial switch
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

### Stow

```sh
# edit files in stow/ and then run:
dotfiles-stow
```

Stow forbids slashes in package names, so each level is its own invocation:

| Package | Applies to |
| --- | --- |
| `stow/shared/` | every machine |
| `stow/platform/{Darwin,Linux}/` | matching `uname -s` |
| `stow/kaizen/` | kaizen hosts, where `/etc/kaizen` exists (`renoir`, `wily`) |
| `stow/host/<hostname>/` | that machine only; optional |

`--adopt` absorbs any real file that has replaced a managed symlink into the
repo instead of aborting; review the result with `git diff` before committing.

#### Shell

The shell entrypoint is `stow/shared/.zshrc`, which sources
`stow/shared/.zshrc_user`. The user file loads the shell configuration chain:

1. [`stow/shared/.shell/exports.sh`](stow/shared/.shell/exports.sh) — PATH
   (including [`bin/`](stow/shared/.shell/bin/) utils), globals, env vars
2. [`stow/shared/.shell/aliases.sh`](stow/shared/.shell/aliases.sh) — shell
   aliases
3. [`stow/shared/.shell/sourcing.sh`](stow/shared/.shell/sourcing.sh) — tool
   initialization, plugins, completions

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
