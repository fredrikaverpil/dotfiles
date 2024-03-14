-- Fix conceallevel for json files
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup("json_conceal", { clear = true }),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

return {

  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "prettier" })
        end,
      },
    },
    ft = { "json", "jsonc", "json5" },
    opts = {
      formatters_by_ft = {
        json = { "prettier" }, -- TODO: would be nice if biome existed...
      },
    },
  },
}
