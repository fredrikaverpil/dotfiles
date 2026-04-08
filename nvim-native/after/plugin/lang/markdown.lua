-- Markdown: formatters, linters, preview.
-- Runs after plugin/ is fully sourced (after/plugin/ loading order).

vim.pack.add({
  { src = "https://github.com/iamcco/markdown-preview.nvim" },
})

require("conform").setup({
  formatters_by_ft = {
    markdown = { "prettier" },
  },
  formatters = {
    prettier = {
      prepend_args = { "--prose-wrap", "always", "--print-width", "80", "--tab-width", "2" },
    },
  },
})

require("lint").linters_by_ft.markdown = { "markdownlint" }

require("lint").linters.markdownlint = vim.tbl_deep_extend("force", require("lint").linters.markdownlint or {}, {
  args = {
    "--config",
    vim.env.DOTFILES .. "/extras/templates/.markdownlint.json",
    "--stdin",
  },
})
