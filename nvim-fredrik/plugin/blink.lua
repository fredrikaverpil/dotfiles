-- Top-level so blink.cmp is on the rtp before any on_vim_enter runs:
-- Other plugins, like lsp.lua requires it to be on rtp.
vim.pack.add({
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.*") },
  { src = "https://github.com/rafamadriz/friendly-snippets" },
})

require("lazyload").on_vim_enter(function()
  local lang = require("lang").spec()

  if #lang.blink_packs > 0 then
    vim.pack.add(lang.blink_packs)
  end
  for _, setup in ipairs(lang.blink_setup) do
    setup()
  end

  local default_sources = { "lsp", "path", "snippets", "buffer", "lazydev" }
  -- Filetype-bound sources stay out of `default` so they aren't queried in
  -- every buffer.
  local per_filetype = lang.blink_per_filetype
  local providers = {
    snippets = {
      opts = {
        friendly_snippets = true,
        search_paths = { vim.env.DOTFILES .. "/nvim-fredrik/snippets" },
      },
    },
    lazydev = {
      name = "LazyDev",
      module = "lazydev.integrations.blink",
      score_offset = 100,
    },
  }
  for name, provider in pairs(lang.blink_providers) do
    providers[name] = provider
  end

  require("blink.cmp").setup({
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
        list = {
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
      },
      keymap = {
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
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
      per_filetype = per_filetype,
      providers = providers,
    },
  })
end)
