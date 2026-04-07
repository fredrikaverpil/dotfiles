-- blink.indent: indent guides with scope highlighting.

vim.pack.add({
  { src = "https://github.com/Saghen/blink.indent" },
})

require("blink.indent").setup({
  blocked = {
    filetypes = { include_defaults = true, "snacks_picker_preview" },
  },
  static = {
    enabled = false,
  },
  scope = {
    highlights = { "BlinkIndentScope" },
  },
})
