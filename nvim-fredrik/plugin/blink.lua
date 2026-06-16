-- Top-level so blink.cmp is on the rtp before any on_vim_enter runs:
-- Other plugins, like lsp.lua requires it to be on rtp.
vim.pack.add({
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.*") },
  { src = "https://github.com/rafamadriz/friendly-snippets" },
})

require("lazyload").on_vim_enter(function()
  local default_sources = { "lsp", "path", "snippets", "buffer", "lazydev" }
  -- Filetype-bound sources stay out of `default` so they aren't queried in
  -- every buffer. The provider plugins themselves are installed by the
  -- respective plugin/lang/*.lua files.
  local per_filetype = {
    sql = { inherit_defaults = true, "dadbod" },
    mysql = { inherit_defaults = true, "dadbod" },
    plsql = { inherit_defaults = true, "dadbod" },
    markdown = { inherit_defaults = true, "markdown" },
  }
  local providers = {
    snippets = {
      opts = {
        friendly_snippets = true,
        search_paths = { vim.env.DOTFILES .. "/nvim-fredrik/snippets" },
      },
    },
    dadbod = {
      name = "Dadbod",
      module = "vim_dadbod_completion.blink",
    },
    lazydev = {
      name = "LazyDev",
      module = "lazydev.integrations.blink",
      score_offset = 100,
    },
    markdown = {
      name = "RenderMarkdown",
      module = "render-markdown.integ.blink",
    },
  }

  if Config.use_treesitter_parser then
    per_filetype.go = { inherit_defaults = true, "go_pkgs" }
    providers.go_pkgs = {
      name = "Import",
      module = "blink-go-import",
    }
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
