{ config, pkgs, lib, dotfiles, ... }@args:

{
  options = {
    dotfiles.extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages for this host";
    };
  };

  config = {
    # Home Manager setup
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.fredrik = { config, lib, ... }: {
    # Ensure any git submodules are initialized in ~/.dotfiles
    home.activation.initDotfilesSubmodules = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -d "$HOME/.dotfiles/.git" ]; then
        echo "Initializing any git submodules in ~/.dotfiles..."
        cd "$HOME/.dotfiles"
        if ! $DRY_RUN_CMD ${pkgs.git}/bin/git submodule update --init --recursive; then
          echo "Warning: Failed to initialize git submodules"
          exit 1
        fi
        echo "Git submodules initialized"
      fi
    '';

    # Run stow installer to create dotfile symlinks
    home.activation.runStowInstaller = lib.hm.dag.entryAfter ["initDotfilesSubmodules"] ''
      if [ -f "$HOME/.dotfiles/stow/symlink.sh" ] && [ -x "$HOME/.dotfiles/stow/symlink.sh" ]; then
        echo "Running stow installer..."
        cd "$HOME/.dotfiles/stow"
        export PATH="${pkgs.stow}/bin:${pkgs.bash}/bin:$PATH"
        if ! $DRY_RUN_CMD ./symlink.sh; then
          echo "Warning: Stow installation failed"
          exit 1
        fi
        echo "Stow installation completed"
      else
        echo "Warning: ~/.dotfiles/stow/symlink.sh not found or not executable"
      fi
    '';

    # Common packages available on both platforms
    home.packages = with pkgs; [
      # ========================================================================
      # Core System & Shell Tools
      # ========================================================================
      bash
      bat
      curl
      direnv
      eza
      fzf
      git
      htop
      jq
      ncurses
      rsync
      stow  # GNU Stow for dotfile management
      tmux
      tree
      vim
      wget
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
      shellcheck
      hadolint
      
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
      kitty.terminfo

      # ========================================================================
      # Infrastructure & Cloud
      # ========================================================================
      opentofu
      
    ] ++ args.config.dotfiles.extraPackages;



    # Common program settings
    # Git is managed via package + dotfile symlink (.gitconfig)

    };
  };
}
