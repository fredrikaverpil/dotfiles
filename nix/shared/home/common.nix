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

  # Bob's neovim proxy (~/.local/share/bob/nvim-bin/nvim) is a copy of the bob
  # binary and inherits its permissions. The Nix-store bob is read-only, so the
  # proxy is too, and the next `bob use` fails to overwrite it ("Failed to copy
  # file"). Wrap bob to make the proxy writable right before every invocation.
  bobWrapped = pkgs.symlinkJoin {
    name = "bob-nvim-wrapped";
    paths = [ unstable.bob-nvim ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/bob \
        --run 'p="$HOME/.local/share/bob/nvim-bin/nvim"; [ -e "$p" ] && chmod u+w "$p" 2>/dev/null || true'
    '';
  };

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
      # (mkCurlInstaller "vibe" "Mistral Vibe" "https://mistral.ai/vibe/install.sh" "$HOME/.local/bin/vibe")
      # (mkCurlInstaller "agy" "Antigravity CLI" "https://antigravity.google/cli/install.sh"
      #   "$HOME/.local/bin/agy"
      # )

      # OpenCode installs to ~/.opencode/bin/opencode, use --no-modify-path to prevent shell config modification
      (mkCustomInstaller "opencode" "OpenCode AI" ''
        ${pkgs.curl}/bin/curl -fsSL https://opencode.ai/install | ${pkgs.bash}/bin/bash -s -- --no-modify-path
      '' "$HOME/.opencode/bin/opencode")
    ];

    # npm packages via bun (macOS only, mergeable across config levels)
    packageTools.npmPackages = [
      "@google/gemini-cli"
      "@openai/codex"
      "@earendil-works/pi-coding-agent"
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
      bobWrapped
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
      bfs
      devbox
      devenv
      mise
      dust
      fd
      gnumake
      go-task
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
        bun
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

    # Bootstrap Neovim via Bob on first rebuild
    home.activation.bobNeovimBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -x "$HOME/.local/share/bob/nvim-bin/nvim" ]]; then
        echo "Bootstrapping Neovim via Bob..."
        ${bobWrapped}/bin/bob use stable
      fi
    '';

    # Bob config path (unified across macOS/Linux, since defaults differ)
    home.sessionVariables.BOB_CONFIG = "$HOME/.config/bob/config.toml";

  };
}
