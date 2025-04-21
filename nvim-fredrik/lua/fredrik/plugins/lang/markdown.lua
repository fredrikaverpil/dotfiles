-- Fix conceallevel for markdown files
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup("markdown_conceal", { clear = true }),
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.conceallevel = 2
  end,
})

return {

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "markdown", "markdown_inline", "tex", "latex" },
    },
  },

  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "prettier", "mdformat", "markdown-toc" })
        end,
      },
    },
    opts = {
      formatters_by_ft = {
        markdown = { "prettier" },
      },
      formatters = {
        prettier = {
          -- https://prettier.io/docs/en/options.html
          prepend_args = { "--prose-wrap", "always", "--print-width", "80", "--tab-width", "2" },
        },
        mdformat = {
          -- https://github.com/einride/sage/blob/master/tools/sgmdformat/tools.go
          prepend_args = { "--number", "--wrap", "80" },
        },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "markdownlint" })
        end,
      },
    },
    opts = {
      linters_by_ft = {
        -- NOTE: disable inline markdown linting with e.g.
        -- <!-- markdownlint-disable MD013 MD014 MD015 -->
        markdown = { "markdownlint" },
      },
    },
  },

  {
    "iamcco/markdown-preview.nvim",
    lazy = true,
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = true,
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.icons",
      {
        "saghen/blink.cmp",
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
          sources = {
            default = { "markdown" },
            providers = {
              markdown = { name = "RenderMarkdown", module = "render-markdown.integ.blink" },
            },
          },
        },
        opts_extend = {
          "sources.default",
        },
      },
      {
        -- "epwalsh/obsidian.nvim",
        "obsidian-nvim/obsidian.nvim",
        opts = {
          ui = { enable = false },
        },
      },
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      heading = {
        enabled = false,
        -- width = "block",
        -- sign = false,
        -- icons = {},
      },
    },
    keys = require("fredrik.config.keymaps").setup_markdown_keymaps(),
  },
}
