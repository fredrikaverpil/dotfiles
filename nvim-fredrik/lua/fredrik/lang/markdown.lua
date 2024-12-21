-- Fix conceallevel for markdown files
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup("markdown_conceal", { clear = true }),
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})

return {

  {
    "stevearc/conform.nvim",
    lazy = true,
    ft = { "markdown" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "prettier", "mdformat" })
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
    lazy = true,
    ft = { "markdown" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "markdownlint", "markdown-toc" })
        end,
      },
    },
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint", "markdown-toc" },
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
