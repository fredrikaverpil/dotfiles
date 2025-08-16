# Shared home-manager configuration that gets imported by user-specific configs
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  # Define custom option for npm tools that can be extended by host/platform configs
  options.npmTools = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "opencode-ai@latest"
      # "@anthropic-ai/claude-code@latest"
    ];
    description = "List of npm packages to install globally";
  };

  config = {
    home.activation.handleDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

      # Generic development
      gnumake
      ripgrep
      fd
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
        cmake
        gcc
        go
        nixfmt-rfc-style # cannot be installed via Mason on macOS, so installed here instead
        nodejs
        npm-check-updates
        python3
        ruby
        rustup # run `rustup update stable` to get latest rustc, cargo, rust-analyzer etc.
        tree-sitter
        uv
        yarn
      ];
    };

    # CLI tools provided by npm
    home.activation.installNpmTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -e
      export NPM_CONFIG_PREFIX="$HOME/.nix-npm-tools"
      export PATH="$HOME/.nix-npm-tools/bin:$PATH"

      # Ensure npm tools directory exists
      mkdir -p "$HOME/.nix-npm-tools"

      # Use the collected npm tools from config.npmTools
      NPM_TOOLS=(${lib.concatStringsSep " " (map (pkg: "\"${pkg}\"") config.npmTools)})

      echo "Installing/updating npm-based CLI tools..."
      # Ensure node binary is available to npm postinstall scripts
      export PATH="${pkgs.nodejs_24}/bin:$PATH"

      for tool in "''${NPM_TOOLS[@]}"; do
        echo "Processing $tool..."
        
        # Extract package name from tool string (remove @latest suffix)
        package_name=$(echo "$tool" | sed 's/@latest$//')
        
        # Extract binary name (last part after /)
        binary_name=$(basename "$package_name")
        
        # Check if tool is installed and up to date
        if ! command -v "$binary_name" &> /dev/null; then
          echo "Installing $tool (not found)..."
          if ! $DRY_RUN_CMD npm install -g "$tool"; then
            echo "Warning: Failed to install $tool"
          fi
        elif npm outdated -g "$package_name" 2>/dev/null | grep -q "$package_name"; then
          echo "Updating $tool (outdated)..."
          if ! $DRY_RUN_CMD npm install -g "$tool"; then
            echo "Warning: Failed to update $tool"
          fi
        fi
      done

      echo "npm tools installation complete"

    '';

    # Add npm tools to PATH permanently
    home.sessionPath = [ "$HOME/.nix-npm-tools/bin" ];

    # Additional packages are added in individual user configurations
  };
}
