-- Completion via blink.cmp.

vim.pack.add({
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.*") },
  { src = "https://github.com/rafamadriz/friendly-snippets" },
  { src = "https://github.com/edte/blink-go-import.nvim" },
  { src = "https://github.com/kristijanhusak/vim-dadbod-completion" },
})

require("blink-go-import").setup()

require("blink.cmp").setup({
  keymap = { preset = "default" },
  cmdline = {
    enabled = true,
    completion = {
      menu = { auto_show = true },
      ghost_text = { enabled = true },
    },
    keymap = { preset = "cmdline" },
  },
  completion = {
    trigger = {
      prefetch_on_insert = false,
      show_on_keyword = true,
    },
    list = {
      selection = {
        preselect = false,
        auto_insert = false,
      },
    },
    documentation = { auto_show = true },
  },
  signature = { enabled = true },
  sources = {
    default = { "lazydev", "lsp", "path", "snippets", "buffer", "markdown", "go_pkgs", "dadbod" },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
      markdown = {
        name = "RenderMarkdown",
        module = "render-markdown.integ.blink",
      },
      go_pkgs = {
        name = "Import",
        module = "blink-go-import",
      },
      dadbod = {
        name = "Dadbod",
        module = "vim_dadbod_completion.blink",
      },
    },
  },
})
