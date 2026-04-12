require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.*") },
    { src = "https://github.com/rafamadriz/friendly-snippets" },
  })

  local default_sources = { "lsp", "path", "snippets", "buffer", "dadbod", "lazydev", "markdown" }
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
    table.insert(default_sources, "go_pkgs")
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
      providers = providers,
    },
  })
end)
