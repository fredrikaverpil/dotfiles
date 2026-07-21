# The shared development toolchain: language runtimes and dev utilities used by
# Neovim's LSPs/linters/formatters, and exposed as the `dev` devshell in
# flake.nix (`nix develop ~/.dotfiles#dev`) for use outside Neovim — e.g. Claude
# Code under Remote Control. Imported by BOTH flake.nix and
# nix/shared/home/common.nix so the devshell and Neovim stay in lockstep (same
# nixpkgs-unstable instance -> identical store paths).
#
# NOTE: gcc/cmake and the Lua 5.1 stack are intentionally NOT here — they are
# Neovim-only extras (see common.nix). `mkShell` gives the devshell a stdenv C
# compiler automatically.
#
# NOTE: the standalone-package managers uv and deno are intentionally NOT here.
# They live on the base PATH (home.packages in darwin.nix/linux.nix) so they
# work in a plain shell (uv venv auto-activation, deno-installed npm tools) and
# are inherited into both Neovim and this devshell. Keeping uv out of the list
# also keeps it out of the Neovim context (see commit "comment out uv inside
# neovim context").
pkgs: with pkgs; [
  beamPackages.elixir
  go_latest
  nixfmt # cannot be installed via Mason on macOS, so installed here instead
  nodejs # required by github copilot
  npm-check-updates
  python3
  ruby
  rustup # run `rustup update stable` to get latest rustc, cargo, rust-analyzer etc.
  tree-sitter
  yarn
]
