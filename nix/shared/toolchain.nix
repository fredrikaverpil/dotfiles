# The shared development toolchain, injected into Neovim and Claude Code by
# their wrappers (stow/shared/.shell/bin/) and exposed as the `dev` devshell
# (flake.nix). Kept off the shell PATH; updated by `nix flake update`.
#
# A project overrides a tool in its own mise.toml, whose shims come ahead of
# this list; a shim for a tool the project does not pin falls through to it.
# A tool broken for every project is fixed here instead (e.g. overrideAttrs),
# with an entry in kaizen/docs/issues.md.
#
# Authored `with unstable`; write `stable.<name>` to pin an entry to stable.
{
  stable,
  unstable,
}:
with unstable;
[
  beamPackages.elixir
  go_latest
  nixfmt # nix
  nodejs
  python3
  ruby
  rustup # run `rustup update stable` to get latest rustc, cargo, rust-analyzer etc.
  tree-sitter
  uv

  # LSPs, formatters, linters; the trailing comment is the language/tool.
  actionlint # yaml (github actions)
  api-linter # protobuf
  basedpyright # python
  bash-language-server # bash
  biome # json
  buf # protobuf
  delve # go
  dockerfile-language-server # docker
  elixir-ls # elixir; needs the Elixir above
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
]
