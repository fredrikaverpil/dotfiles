# Shared home-manager configuration that gets imported by user-specific configs
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in {
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

  # Common packages available on all platforms
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
    # neovim-custom # from custom overlay
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
    exiftool
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
    kitty.terminfo # Terminal emulator terminfo for SSH compatibility
    # ghostty.terminfo  # Terminal emulator terminfo - disabled due to broken package
  ];

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-custom; # from overlay
    extraPackages = with unstable; [
      # For plugins and Mason, which needs extra tools to build or run.
      # NOTE: because of useGlobalPkgs=true, all packages from home.packages are also available here
      bun
      gcc
      go
      nodejs_22
      npm-check-updates
      python3
      ruby
      tree-sitter
      uv
      yarn

      # Instead of rustup; include the toolchain directly
      cargo
      rustc
      rustfmt
      clippy
      rust-analyzer
    ];
  };

  # Additional packages are added in individual user configurations
}
