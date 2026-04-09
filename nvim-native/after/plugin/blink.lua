vim.pack.add({
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.*") },
  { src = "https://github.com/rafamadriz/friendly-snippets" },
})

require("defer").on_ui_enter(function()
  local registry = require("registry")

  -- Build sources.default from base sources + registered providers
  local default_sources = { "lsp", "path", "snippets", "buffer" }
  if registry.blink.sources and registry.blink.sources.providers then
    for name, _ in pairs(registry.blink.sources.providers) do
      table.insert(default_sources, name)
    end
  end

  local config = vim.tbl_deep_extend("force", {
    keymap = {
      ["<C-e>"] = { "hide", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      ["<C-space>"] = { "show" },
    },
    cmdline = {
      enabled = true,
      completion = {
        menu = { auto_show = true },
        ghost_text = { enabled = true },
      },
      keymap = {
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
      },
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
      menu = {
        draw = {
          treesitter = { "lsp" },
        },
      },
    },
    signature = { enabled = true },
    appearance = {
      kind_icons = require("icons").kinds,
    },
    sources = {
      default = default_sources,
      providers = {
        snippets = {
          opts = {
            friendly_snippets = true,
            search_paths = { vim.env.DOTFILES .. "/nvim-native/snippets" },
          },
        },
      },
    },
  }, registry.blink)

  -- Restore computed default (deep merge would have replaced it if any provider set sources.default)
  config.sources.default = default_sources

  require("blink.cmp").setup(config)
end)
