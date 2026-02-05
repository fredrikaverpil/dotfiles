# Shared home-manager configuration that gets imported by user-specific configs
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # Import helper functions for self-managed CLIs
  inherit (config.selfManagedCLIs.helpers)
    mkCurlInstaller
    mkWgetInstaller
    mkCustomInstaller
    ;
in
{
  imports = [
    ./self-managed-clis.nix
    ./package-tools.nix
  ];

  config = {

    # Self-managed CLI tools (installed once, auto-update thereafter)
    selfManagedCLIs.clis = [
      (mkCurlInstaller "claude" "Claude Code" "https://claude.ai/install.sh" "$HOME/.local/bin/claude")
      (mkCurlInstaller "agent" "Cursor Agent" "https://cursor.com/install" "$HOME/.local/bin/agent")
      # OpenCode installs to ~/.opencode/bin/opencode, use --no-modify-path to prevent shell config modification
      (mkCustomInstaller "opencode" "OpenCode AI" ''
        ${pkgs.curl}/bin/curl -fsSL https://opencode.ai/install | ${pkgs.bash}/bin/bash -s -- --no-modify-path
      '' "$HOME/.opencode/bin/opencode")
    ];

    # npm packages via bun (macOS only, mergeable across config levels)
    packageTools.npmPackages = [
      "@google/gemini-cli"
      "@openai/codex"
    ];

    # Python CLI tools via uv (mergeable across config levels)
    packageTools.uvTools = [
      {
        package = "sqlit-tui";
        inject = [ "google-cloud-bigquery" ];
      }
    ];

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
      coreutils # provides e.g. timout
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
      unstable.bob-nvim
      wget
      yq
      yazi
      unzip
      zsh-autosuggestions
      zsh-syntax-highlighting
      zoxide
      starship

      # ========================================================================
      # Nixpkgs Tools
      # ========================================================================
      nixpkgs-track

      # ========================================================================
      # Development & Language Toolchains
      # ========================================================================
      # Language-specific
      uv

      # Generic development
      dust
      fd
      gnumake
      go-task
      # pre-commit # requires swift, which is problematic and very expensive to build on macOS
      ripgrep

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
      gnused # GNU tools (for macOS compatibility)
      imagemagick
      ollama
      slides
      chafa # Required for showing images in slides

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

    # Tooling available only in Neovim.
    # Written to a file so the nvim wrapper can inject them into PATH at launch,
    # keeping these tools off the regular shell PATH.
    home.file.".config/nvim-deps-path".text = lib.makeBinPath (
      with unstable;
      [
        bun
        cmake
        gcc
        go_1_25
        lua51Packages.lua # Neovim requires Lua 5.1
        lua51Packages.luarocks # Neovim requires Lua 5.1
        nixfmt # cannot be installed via Mason on macOS, so installed here instead
        nodejs # required by github copilot
        npm-check-updates
        python3
        ruby
        rustup # run `rustup update stable` to get latest rustc, cargo, rust-analyzer etc.
        tree-sitter
        uv
        yarn
      ]
    );

    # Bootstrap Neovim via Bob on first rebuild
    home.activation.bobNeovimBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -x "$HOME/.local/share/bob/nvim-bin/nvim" ]]; then
        echo "Bootstrapping Neovim via Bob..."
        ${unstable.bob-nvim}/bin/bob use stable
      fi
    '';

    # Bob config path (unified across macOS/Linux, since defaults differ)
    home.sessionVariables.BOB_CONFIG = "$HOME/.config/bob/config.toml";

  };
}
