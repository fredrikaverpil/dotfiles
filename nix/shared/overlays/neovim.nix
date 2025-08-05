final: prev: let
  # Centralized version and hash management
  #
  # To convert SHA256 from GitHub releases to Nix format:
  # 1. Get hex hash from GitHub (e.g., "17d22826f19fe28a11f9ab4bee13c43399fdcce485eabfa2bea6c5b3d660740f")
  # 2. Convert to base64: echo "HEX_HASH" | xxd -r -p | base64
  # 3. Add "sha256-" prefix: "sha256-F9IoJvGf4ooR+atL7hPEM5n9zOSF6r+ivqbFs9ZgdA8="
  neovimReleases = {
    "0.11.3" = {
      "nvim-macos-arm64.tar.gz" = "sha256-F9IoJvGf4ooR+atL7hPEM5n9zOSF6r+ivqbFs9ZgdA8=";
      "nvim-macos-x86_64.tar.gz" = "sha256-9RtGAaOQwH7NC99G1SwGCrqI6tuyrDol8tlT8s4TjSM=";
      "nvim-linux-arm64.tar.gz" = "sha256-ioMiiboqF5GLeokxYPzEskuocUGloHzbtzBNU4NMDEA=";
      "nvim-linux-x86_64.tar.gz" = "sha256-qbJBV2cushj/PjPvP4wI2yb4kxxcBL2w5HE3HdHf5j4=";
    };
  };

  # Nightly hashes
  #
  # Run `nineovim-nightly-hashes` to get the latest nightly hashes.
  nightlyHashes = {
    "nvim-linux-arm64.tar.gz" = "sha256-jgqwMS2O9gjfaQ6pUHCAOMCQN1SOZvAA6I8LxIYoDBk=";
    "nvim-linux-x86_64.tar.gz" = "sha256-LMQneeMkm570KDiLNhWQ8rPZOBN7qOkBpAVy5tYcWQc=";
    "nvim-macos-x86_64.tar.gz" = "sha256-+q39O4kMUwO5ejk1VMZbeFy2ogzRb3nbYsSzqYpKKHE=";
    "nvim-macos-arm64.tar.gz" = "sha256-uHMYxpSb3cVrtRikuc/3C1EO/o85Wt/CPhbDoOXgE9A=";
  };

  # Helper function to fetch Neovim releases
  fetchNeovimRelease = {
    version,
    isNightly ? false,
  }: let
    # Determine the correct asset name based on system
    assetName =
      if prev.stdenv.isDarwin
      then
        if prev.stdenv.isAarch64
        then "nvim-macos-arm64.tar.gz"
        else "nvim-macos-x86_64.tar.gz"
      else if prev.stdenv.isAarch64
      then "nvim-linux-arm64.tar.gz"
      else "nvim-linux-x86_64.tar.gz";

    releaseTag =
      if isNightly
      then "nightly"
      else "v${version}";

    # Get the correct hash for this version/platform
    sha256 =
      if isNightly
      then nightlyHashes.${assetName}
      else neovimReleases.${version}.${assetName};
  in
    prev.stdenv.mkDerivation rec {
      pname =
        if isNightly
        then "neovim-nightly"
        else "neovim-latest";
      inherit version;

      src = prev.fetchurl {
        url = "https://github.com/neovim/neovim/releases/download/${releaseTag}/${assetName}";
        inherit sha256;
      };

      nativeBuildInputs = with prev; [makeWrapper];

      # No build phase needed - we're using pre-built binaries
      dontBuild = true;
      dontConfigure = true;

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r * $out/

        # Make sure the binary is executable
        chmod +x $out/bin/nvim

        # On macOS, remove quarantine attributes if they exist
        ${prev.lib.optionalString prev.stdenv.isDarwin ''
          if command -v xattr >/dev/null 2>&1; then
            xattr -c $out/bin/nvim 2>/dev/null || true
          fi
        ''}

        runHook postInstall
      '';

      meta = with prev.lib; {
        description =
          if isNightly
          then "Neovim nightly build"
          else "Neovim ${version}";
        mainProgram = "nvim";
      };
    };
in {
  # Declaratively specify which versions you want
  neovim-latest = fetchNeovimRelease {version = "0.11.3";};
  neovim-nightly = fetchNeovimRelease {
    version = "nightly";
    isNightly = true;
  };

  # Alias for consistency - points to the regular nixpkgs neovim
  neovim-stable = prev.neovim;
}
