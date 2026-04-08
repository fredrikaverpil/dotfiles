local registry = require("registry")

vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

vim.g.auto_format = true

require("conform").setup(registry.conform)

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("native-conform", { clear = true }),
  pattern = "*",
  callback = function(args)
    if vim.g.auto_format then
      require("conform").format({
        bufnr = args.buf,
        timeout_ms = 5000,
        lsp_format = "fallback",
      })
    end
  end,
})

vim.keymap.set("n", "<leader>uf", require("toggle").auto_format, { desc = "Toggle auto-format" })
