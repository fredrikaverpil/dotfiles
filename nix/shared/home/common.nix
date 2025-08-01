# Shared home-manager configuration that gets imported by user-specific configs
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Handle dotfiles - use local clone if available, otherwise use flake input
  home.activation.handleDotfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    DOTFILES_PATH=""

    # Check if dotfiles are already cloned locally
    if [ -d "$HOME/.dotfiles/.git" ]; then
      echo "Using existing dotfiles at ~/.dotfiles"
      DOTFILES_PATH="$HOME/.dotfiles"

      # Initialize git submodules for local clone
      echo "Initializing any git submodules..."
      cd "$DOTFILES_PATH"
      if ! $DRY_RUN_CMD ${pkgs.git}/bin/git submodule update --init --recursive; then
        echo "Warning: Failed to initialize git submodules"
        exit 1
      fi
      echo "Git submodules initialized"
    else
      echo "Using dotfiles from flake input"
      DOTFILES_PATH="${inputs.dotfiles}"
    fi

    # Run stow installer script from determined path
    if [ -f "$DOTFILES_PATH/stow/install.sh" ] && [ -x "$DOTFILES_PATH/stow/install.sh" ]; then
      echo "Running stow installer from $DOTFILES_PATH..."
      export PATH="${pkgs.stow}/bin:${pkgs.bash}/bin:$PATH"
      if ! $DRY_RUN_CMD "$DOTFILES_PATH/stow/install.sh"; then
        echo "Warning: Stow installation failed"
        exit 1
      fi
    else
      echo "Warning: install.sh not found or not executable in $DOTFILES_PATH/stow"
      exit 1
    fi
  '';

  # Common packages available on both platforms
  home.packages = with pkgs; [
    # ========================================================================
    # Core System & Shell Tools
    # ========================================================================
    atuin
    bash
    bat
    curl
    direnv
    eza
    fzf
    git
    git-lfs
    htop
    jq
    ncurses
    rsync
    stow # GNU Stow for dotfile management
    tmux
    tree
    vim
    wget
    yq
    unzip
    zsh-autosuggestions
    zsh-syntax-highlighting
    zoxide
    starship

    # ========================================================================
    # Development & Language Toolchains
    # ========================================================================
    # Language-specific
    uv
    rustup

    # Generic development
    gnumake
    ripgrep
    fd
    cmake
    tree-sitter
    pre-commit

    # ========================================================================
    # Git & Version Control
    # ========================================================================
    gh
    lazygit
    lazydocker

    # ========================================================================
    # Network, API & Database
    # ========================================================================
    grpcurl
    grpcui
    postgresql
    # mysql80  # Temporarily disabled due to boost build failure on macOS

    # ========================================================================
    # Media, AI & Utilities
    # ========================================================================
    asciinema
    imagemagick
    ollama
    gnused # GNU tools (for macOS compatibility)


    # ========================================================================
    # Infrastructure & Cloud
    # ========================================================================
    opentofu

    # ========================================================================
    # Terminal Support
    # ========================================================================
    kitty.terminfo    # Terminal emulator terminfo for SSH compatibility
    # ghostty.terminfo  # Terminal emulator terminfo - disabled due to broken package
  ];

  # Additional packages are added in individual user configurations
}
