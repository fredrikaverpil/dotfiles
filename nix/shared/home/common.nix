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
    ./llm-agents.nix
  ];

  config = {

    # LLM agent CLIs from the numtide/llm-agents.nix flake input (mergeable
    # across config levels; platform/host configs can add more)
    llmAgents = [
      "claude-code"
      "gemini-cli"
      "opencode"
      "pi"
    ];

    home.activation.handleDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Check if dotfiles are already cloned locally
      if [ -d "$HOME/.dotfiles/.git" ]; then
        echo "Using existing dotfiles at ~/.dotfiles"
        DOTFILES_PATH="$HOME/.dotfiles"

        # Initialize git submodules for local clone, skipping the ones under
        # another host's directory: those are that host's private config, which
        # this host cannot clone. The flake reads an uninitialised submodule as
        # an empty directory, so a failure here only warns; git's credential
        # helper is not on the activation PATH either way.
        cd "$DOTFILES_PATH"
        submodules=$(${pkgs.git}/bin/git config -f .gitmodules --get-regexp '\.path$' \
          | cut -d' ' -f2 \
          | ${pkgs.gawk}/bin/awk -v host="$(uname -n | cut -d. -f1)" \
              '$0 !~ "^nix/hosts/" || $0 ~ "^nix/hosts/" host "/"')
        if [ -z "$submodules" ]; then
          echo "No git submodules for this host"
        elif $DRY_RUN_CMD ${pkgs.git}/bin/git submodule update --init --recursive -- $submodules; then
          echo "Git submodules initialized"
        else
          echo "Warning: git submodules were not initialized; this host's config falls back to what is checked out"
        fi

        echo "Stowing dotfiles from $DOTFILES_PATH..."
        PATH="${pkgs.stow}/bin:${pkgs.bash}/bin:$PATH" \
          $DRY_RUN_CMD bash "$DOTFILES_PATH/stow/shared/.shell/bin/dotfiles-stow" "$DOTFILES_PATH"
      else
        echo "Warning: ~/.dotfiles is not cloned; clone github.com/fredrikaverpil/dotfiles there and rebuild to stow"
      fi
    '';

    # Common packages available on all platforms
    home.packages = with pkgs; [
      # ========================================================================
      # Core System & Shell Tools
      # ========================================================================
      atuin
      bat
      eza
      fzf
      git
      git-lfs
      htop
      jq
      unstable.neovim
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
      # Unstable: the Pi's pinned uv is too old for the relative-date
      # `exclude-newer` in stow/shared/.config/uv/uv.toml.
      unstable.uv

      # Generic development
      bfs
      devbox
      devenv
      # Unstable: the Pi's pinned mise is too old for stow/shared/.config/mise.
      unstable.mise
      dust
      fd
      gnumake
      ripgrep
      ugrep

      # ========================================================================
      # Git & Version Control
      # ========================================================================
      gh
      lazygit
      lazydocker
      docker-client # Docker CLI only (no engine); routes to whatever DOCKER_HOST points at

      # ========================================================================
      # Network, API & Database
      # ========================================================================
      grpcurl
      grpcui
      postgresql

      # ========================================================================
      # Media & Utilities
      # ========================================================================
      asciinema
      exiftool
      imagemagick

      # ========================================================================
      # Infrastructure & Cloud
      # ========================================================================
      opentofu

      # ========================================================================
      # Terminal Support
      # ========================================================================

      # NOTE: do NOT add `ghostty.terminfo` here (or anywhere built for the Pi).
      # Unlike kitty's, ghostty's terminfo is an output of the full ghostty
      # build, which is uncached for nixos-raspberrypi's nixpkgs — pulling it in
      # recompiles GTK/Ghostty from source on the Pi and crashes it.
      #
      # How xterm-ghostty is provided instead:
      #   - macOS: the Ghostty app installs it.
      #   - SSH targets (e.g. the Pi): Ghostty's client-side ssh-terminfo
      #     integration (shell-integration-features in ghostty/config) installs
      #     it automatically on first connect from a fresh Ghostty window.
      #   - Manual one-off, if ever needed:
      #       infocmp -x xterm-ghostty | ssh <host> 'tic -x -o "$HOME/.terminfo" -'
    ];

    # Tooling available only in Neovim, for what mise
    # (stow/shared/.config/mise) does not provide.
    # Written to a file so the nvim wrapper can inject them into PATH at launch
    # (after the mise shims), keeping these tools off the regular shell PATH.
    home.file.".config/nvim-deps-path".text = lib.makeBinPath (
      with unstable;
      [
        cmake # Neovim's injected PATH has no stdenv cc
        gcc
        lua51Packages.lua # Neovim requires Lua 5.1
        lua51Packages.luarocks # Neovim requires Lua 5.1
        nil # nix; not in mise's registry
        nixfmt # nix; not in mise's registry
      ]
    );

    # Writes ~/.config/direnv/direnvrc sourcing nix-direnv by store path, so
    # `use flake` (.envrc) is cached and correct under both profile modes.
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # nh: nix rebuild wrapper with diffs (`nh os switch`, `nh darwin switch`).
    # Sets NH_FLAKE so no flake path argument is needed.
    programs.nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/.dotfiles";
    };

  };
}
