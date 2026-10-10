# shellcheck shell=bash
# shellcheck source=/dev/null

# ----------------------------
# functions and shell-agnostic
# ----------------------------

# Noctalia session launcher for a console login, beside `kaizen run`.
# /etc/kaizen marks a kaizen host, on NixOS or another distro, so it rules out
# macOS and every other Linux in one test; the inner check then skips hosts
# that do not install niri.
if [ -e /etc/kaizen ]; then
  # `noctalia` starts the niri session `kaizen run` does, with kaizen's units
  # masked and Noctalia v5 in their place.
  if command -v uwsm >/dev/null 2>&1 && command -v niri >/dev/null 2>&1; then
    if [ -e /etc/NIXOS ]; then
      # Noctalia is evaluated, not installed, so it runs from the host's own
      # nixpkgs, which only a NixOS host has. niri's config is kaizen's: its
      # `qs ipc` binds do nothing here and noctalia's own binds are absent.
      # State lives in ~/.config/noctalia and ~/.local/state/noctalia, outside
      # the dotfiles.
      function noctalia() {
        uwsm check may-start || return
        local flake
        flake="$HOME/.dotfiles#nixosConfigurations.$(hostname -s).pkgs.noctalia"
        kaizen units mask
        # uwsm-app puts the shell in app.slice; foreground, so niri owns its
        # life. Named, so `journalctl --user -u noctalia-trial` reaches it.
        uwsm start -e -D niri -- niri --session -- \
          uwsm-app -t service -u noctalia-trial.service -- nix run "$flake"
        kaizen units unmask
      }
    fi
  fi

fi

function virtual_env_activate() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    # check the current folder belong to earlier VIRTUAL_ENV folder
    parentdir="$(dirname "$VIRTUAL_ENV")"
    if [[ "$PWD"/ != "$parentdir"/* ]]; then
      # $VIRTUAL_ENV can be inherited by subshells that never sourced
      # activate, so deactivate (defined by activate) may not exist.
      if declare -f deactivate >/dev/null; then
        deactivate
      else
        unset VIRTUAL_ENV
      fi
    fi
  fi

  if [ -f .python-version ] && [ ! -d ./.venv ]; then
    uv venv
  fi

  if [[ -z "$VIRTUAL_ENV" ]]; then
    # if .venv folder is found then activate the vitualenv
    if [ -d ./.venv ] && [ -f ./.venv/bin/activate ]; then
      source ./.venv/bin/activate

      # if pyproject.toml is found then sync the virtualenv
      if [[ -f pyproject.toml ]]; then
        uv sync --all-groups
      fi
    fi
  fi
}

function zsh_completion() {
  # Set up FPATH for completions - prefer home-manager, then Nix profile, then Homebrew
  if [ -d ~/.local/state/home-manager/gcroots/current-home/home-path/share/zsh/site-functions ]; then
    export FPATH=~/.local/state/home-manager/gcroots/current-home/home-path/share/zsh/site-functions:$FPATH
  fi
  if [ -d ~/.nix-profile/share/zsh/site-functions ]; then
    export FPATH=~/.nix-profile/share/zsh/site-functions:$FPATH
  fi

  if [ -n "$brew_prefix" ]; then
    export FPATH=$brew_prefix/share/zsh/site-functions:$FPATH
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "⚠️ Warning: Homebrew not found on macOS - some shell features may not work properly" >&2
  fi

  # Load zsh plugins - prefer home-manager, then Nix profile, fallback to Homebrew
  if [ -f ~/.local/state/home-manager/gcroots/current-home/home-path/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.local/state/home-manager/gcroots/current-home/home-path/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  elif [ -f ~/.nix-profile/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.nix-profile/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  elif [ -f "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  else
    echo "⚠️ Warning: zsh-autosuggestions not found" >&2
  fi

  if [ -f ~/.local/state/home-manager/gcroots/current-home/home-path/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/.local/state/home-manager/gcroots/current-home/home-path/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  elif [ -f ~/.nix-profile/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source ~/.nix-profile/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  elif [ -f "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  else
    echo "⚠️ Warning: zsh-syntax-highlighting not found" >&2
  fi

  if [ -d "$brew_prefix/share/google-cloud-sdk" ]; then
    source "$brew_prefix/share/google-cloud-sdk/path.zsh.inc"
    source "$brew_prefix/share/google-cloud-sdk/completion.zsh.inc"
  fi

  if [[ -f ~/.orbstack/bin/docker ]]; then
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
  fi

  export FPATH=$DOTFILES/work/zsh/site-functions:$FPATH

  # Makefile completion
  zstyle ':completion:*:*:make:*' tag-order 'targets'
  zstyle ':completion:*:make:*:targets' call-command true

  # mkdir -p ~/.zfunc
  # pass-cli completions zsh > ~/.zfunc/_pass-cli

  autoload -Uz compinit
  compinit
}

function bash_completion() {
  if [ -d "$brew_prefix/share/google-cloud-sdk" ]; then
    source "$brew_prefix/share/google-cloud-sdk/path.bash.inc"
    source "$brew_prefix/share/google-cloud-sdk/completion.bash.inc"
  fi
}

# ----------------------------
# Nix
# ----------------------------

# Source Nix daemon to make nix commands available in PATH
# Moved from .zprofile to maintain centralized shell configuration
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# HACK: Ensure ~/.shell/bin comes before ~/.nix-profile/bin in PATH
add_to_path prepend "$HOME/.shell/bin" # personal and custom scripts

# ----------------------------
# globals
# ----------------------------

brew_prefix="$DOTFILES_BREW_PREFIX"
shell="$DOTFILES_SHELL"

# ----------------------------
# shell-agnostic configuration
# ----------------------------

if [ -f ~/.cargo/env ]; then
  source "$HOME/.cargo/env"
fi

if [ -n "$brew_prefix" ] || [ -d "/nix/store" ]; then
  eval "$(atuin init "$shell" --disable-up-arrow)"
  eval "$(direnv hook "$shell")"
  # eval "$(mise activate "$shell")"
  eval "$(zoxide init "$shell")"
  eval "$(starship init "$shell")"

fi

# ----------------------------
# shell-specific configuration
# ----------------------------

if [[ $shell == "zsh" ]]; then
  zsh_completion
  if [ -n "$brew_prefix" ]; then
    source <(fzf --zsh)
  fi

elif [[ $shell == "bash" ]]; then
  bash_completion
  if [ -n "$brew_prefix" ]; then
    eval "$(fzf --bash)"
  fi

fi

# ----------------------------------
# overrides
# ----------------------------------

function cd() {
  builtin cd "$@" || return
  virtual_env_activate
}
cd . # trigger cd overrides when shell starts

function z() {
  __zoxide_z "$@" && cd . || return
}

function zi() {
  __zoxide_zi "$@" && cd . || return

}
