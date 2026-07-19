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
in
{
  imports = [
    ./package-tools.nix
  ];

  config = {

    # LLM agent CLIs from the numtide/llm-agents.nix flake input (mergeable
    # across config levels; platform/host configs can add more)
    packageTools.llmAgents = [
      "claude-code"
      "codex"
      "gemini-cli"
      "kimi-code"
      "opencode"
      "pi"
    ];

    # npm packages (mergeable across config levels)
    packageTools.npmPackages = [ ];

    # Python CLI tools (mergeable across config levels)
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
      nix-direnv
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
      # NOTE: uv is installed per-platform (darwin.nix / linux.nix), since the
      # stable-pin uv on NixOS is too old for the uv.toml syntax in use.
      #
      # NOTE: Deno installs/runs the npm-managed CLI tools. Unlike node/bun global
      # installs (FHS shebangs, glibc-linked shims), deno shims are /bin/sh
      # scripts exec'ing the nix store deno -> works on NixOS. Unstable for
      # the latest Node-compat fixes (no-op on macOS, where pkgs IS unstable).
      unstable.deno

      # Generic development
      bfs
      devbox
      devenv
      mise
      dust
      fd
      gnumake
      # pre-commit # requires swift, which is problematic and very expensive to build on macOS
      ripgrep
      ugrep

      # ========================================================================
      # Git & Version Control
      # ========================================================================
      gh
      jujutsu
      lazygit
      lazydocker
      docker-client # Docker CLI only (no engine); routes to whatever DOCKER_HOST points at

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
      llama-cpp
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
        cmake
        beamPackages.elixir
        gcc
        go_latest
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

  };
}
