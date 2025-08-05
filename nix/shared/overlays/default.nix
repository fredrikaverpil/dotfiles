# Combines all overlays into a single overlay function
final: prev: (import ./neovim.nix final prev)
# Add other overlays here as needed by merging their results
# // (import ./other-overlay.nix final prev)


