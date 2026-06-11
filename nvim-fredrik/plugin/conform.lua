require("lazyload").on_vim_enter(function()
  vim.g.auto_format = true

  vim.pack.add({
    { src = "https://github.com/stevearc/conform.nvim" },
  })

  -- formatters_by_ft and formatters aggregated from plugin/lang/*.lua via
  -- require("lang").register(). Only cross-language config (prettier, used by
  -- markdown + js/ts) lives here; language-specific config lives in the lang files.
  local lang = require("lang").spec()

  require("conform").setup({
    format_on_save = function()
      if not vim.g.auto_format then
        return
      end
      return { timeout_ms = 5000, lsp_format = "fallback" }
    end,
    formatters_by_ft = lang.formatters_by_ft,
    formatters = vim.tbl_extend("error", {
      prettier = {
        prepend_args = { "--prose-wrap", "always", "--print-width", "80", "--tab-width", "2" },
      },
    }, lang.formatters),
  })

  vim.keymap.set("n", "<leader>uf", function()
    vim.g.auto_format = not vim.g.auto_format
    vim.notify("Auto-format: " .. (vim.g.auto_format and "on" or "off"))
  end, { desc = "Toggle auto-format" })
end)
