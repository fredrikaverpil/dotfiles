vim.g.tabby_keybinding_accept = "<Tab>"
return {

  -- Config with token lives here:
  -- ~/.tabby-client/agent/config.toml
  --
  -- Download, install:
  -- brew install tabbyml/tabby/tabby
  --
  -- Start server:
  -- tabby serve --device metal --model StarCoder-1B
  {
    "TabbyML/vim-tabby",
  },
}
