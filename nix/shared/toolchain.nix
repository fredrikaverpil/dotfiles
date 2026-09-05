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
#
# Channels: this list is authored `with unstable`, so a bare name resolves to
# nixpkgs-unstable (the default — everything here comes from unstable, all
# platforms). To pin an individual entry to stable nixpkgs, write it explicitly
# as `stable.<name>`.
#
# LSPs/linters/formatters: on macOS Mason installs them
# (nvim-fredrik/plugin/mason.lua). On NixOS Mason is disabled — its prebuilt
# glibc binaries fail under stub-ld — so the NixOS-only list below mirrors
# Mason's `ensure_installed`. Keep the two lists in sync. `nixos` is passed by
# the caller: nothing in nixpkgs distinguishes NixOS from other Linux.
{
  stable,
  unstable,
  nixos ? false,
}:
with unstable;
[
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
++ lib.optionals nixos [
  # Kept alphabetical by Mason name; the trailing comment is the language/tool.
  # Not mirrored: codelldb/debugpy (no DAP adapter uses them), rust-analyzer
  # (rustup component).
  actionlint # yaml (github actions)
  api-linter # protobuf
  basedpyright # python
  bash-language-server # bash
  biome # json
  buf # protobuf
  delve # go
  dockerfile-language-server # docker
  elixir-ls # elixir
  gci # go
  gofumpt # go (golines runs it as --base-formatter)
  gotools # go (goimports)
  golangci-lint # go
  golines # go
  gopls # go
  gotestsum # go (neotest)
  graphql-language-service-cli # graphql
  hadolint # docker
  impl # go (go-impl.nvim)
  vscode-langservers-extracted # json (json-lsp)
  lua-language-server # lua
  markdownlint-cli # markdown
  mypy # python
  nil # nix
  prettier # typescript/javascript
  protolint # protobuf
  ruff # python
  rumdl # markdown
  shellcheck # bash (bashls runs it itself; not a nvim-lint linter)
  shfmt # bash
  stylua # lua
  superhtml # html
  taplo # toml
  templ # templ
  terraform-ls # terraform
  tflint # terraform
  ts_query_ls # query
  vtsls # typescript
  yaml-language-server # yaml
  yamlfmt # yaml
  yamllint # yaml
  zls # zig

  # Newer than nixpkgs: comment out the plain entry above and override here.
  # Start with lib.fakeHash for every hash; `nix build` reports the real one on
  # mismatch. Go tools need vendorHash, Rust tools cargoHash.
  # (gopls.overrideAttrs (old: rec {
  #   version = "0.24.0";
  #   src = old.src.override {
  #     tag = "gopls/v${version}";
  #     hash = lib.fakeHash;
  #   };
  #   vendorHash = lib.fakeHash;
  # }))
]
