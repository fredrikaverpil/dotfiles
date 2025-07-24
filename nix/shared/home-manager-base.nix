{ config, pkgs, lib, dotfiles, ... }@args:

# This file contains home-manager settings that are common
# across all hosts (macOS and Linux).

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
    # Ensure git submodules are initialized in ~/.dotfiles
    home.activation.initDotfilesSubmodules = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -d "$HOME/.dotfiles/.git" ]; then
        echo "Initializing git submodules in ~/.dotfiles..."
        cd "$HOME/.dotfiles"
        $DRY_RUN_CMD ${pkgs.git}/bin/git submodule update --init --recursive
        echo "Git submodules initialized"
      fi
    '';

    # Run dotbot installer to create dotfile symlinks
    home.activation.runDotbotInstaller = lib.hm.dag.entryAfter ["initDotfilesSubmodules"] ''
      if [ -f "$HOME/.dotfiles/install" ] && [ -x "$HOME/.dotfiles/install" ]; then
        echo "Running dotbot installer..."
        cd "$HOME/.dotfiles"
        export PATH="${pkgs.python3}/bin:${pkgs.git}/bin:${pkgs.bash}/bin:$PATH"
        $DRY_RUN_CMD ./install
        echo "Dotbot installation completed"
      else
        echo "Warning: ~/.dotfiles/install not found or not executable"
      fi
    '';

    # Common packages available on both platforms
    home.packages = with pkgs; [
      # Core tools
      vim
      tmux
      tree
      curl
      wget
      git
      
      # Shell tools
      bash
      bat
      jq
      fzf
      zsh-autosuggestions
      zsh-syntax-highlighting
      direnv
      atuin
      eza
      starship
      yq
      zoxide
      
      # Development tools
      gnumake
      ripgrep
      fd
      cmake
      tree-sitter
      pre-commit
      shellcheck
      hadolint
      # gcc removed - use nix-shell for C/C++ development
      
      # Git tools
      gh
      lazygit
      lazydocker
      
      # Network/API tools
      grpcurl
      grpcui
      
      # Database tools
      postgresql
      # mysql80  # Temporarily disabled due to boost build failure on macOS
      
      # Media/utility tools
      asciinema
      imagemagick
      
      # Language tools
      uv
      rustup
      
      # Infrastructure tools
      opentofu
      
      # AI/ML tools
      ollama
      
      # GNU tools (for macOS compatibility)
      gnused
      
      # Basic utilities
      htop
      rsync
      
      # Terminal support
      ncurses
      kitty.terminfo
    ] ++ args.config.dotfiles.extraPackages;



    # Common program settings
    # Git is managed via package + dotfile symlink (.gitconfig)

    # Set the state version
    home.stateVersion = "25.05";
    };
  };
}
