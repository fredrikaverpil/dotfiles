# The shared development toolchain, injected into Neovim
# (nix/shared/home/common.nix) and exposed as the `dev` devshell (flake.nix).
#
# Most tools come from the global mise config
# (stow/shared/.config/mise/config.toml), whose shims come ahead of this list.
# Only what mise cannot provide is enabled here; the commented-out entries are
# the nixpkgs equivalents of the mise tools, kept as placeholders.
#
# Authored `with unstable`; write `stable.<name>` to pin an entry to stable.
{
  stable,
  unstable,
}:
with unstable;
[
  beamPackages.elixir # mise has no precompiled Erlang for NixOS
  # go_latest
  nixfmt # nix; not in mise's registry
  # nodejs
  # python3
  # ruby
  rustup # run `rustup update stable` to get latest rustc, cargo, rust-analyzer etc.
  # tree-sitter

  # LSPs, formatters, linters, in the mise config's order; the trailing
  # comment is the language/tool.
  # actionlint # yaml (github actions)
  # api-linter # protobuf
  # basedpyright # python
  # bash-language-server # bash
  # biome # json
  # buf # protobuf
  # delve # go
  # dockerfile-language-server # docker
  elixir-ls # elixir
  # gci # go
  # gofumpt # go (golines runs it as --base-formatter)
  # gotools # go (goimports)
  # golangci-lint # go
  # golines # go
  # gopls # go
  # gotestsum # go (neotest)
  # graphql-language-service-cli # graphql
  # hadolint # docker
  # impl # go (go-impl.nvim)
  # vscode-langservers-extracted # json (json-lsp)
  # lua-language-server # lua
  # markdownlint-cli # markdown
  # mypy # python
  nil # nix; not in mise's registry
  # prettier # typescript/javascript
  # protolint # protobuf
  # ruff # python
  # rumdl # markdown
  # shellcheck # bash (bashls runs it itself; not a nvim-lint linter)
  # shfmt # bash
  # stylua # lua
  # superhtml # html
  # taplo # toml
  # templ # templ
  # terraform-ls # terraform
  # tflint # terraform
  # ts_query_ls # query
  # vtsls # typescript
  # yaml-language-server # yaml
  # yamlfmt # yaml
  yamllint # yaml; not yet available in mise for python 3.15
  # zls # zig
]
