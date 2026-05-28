require("lang").register("json", {
  servers = { "jsonls" },
  mason = { "json-lsp", "biome" },
  formatters_by_ft = { json = { "biome" }, json5 = { "biome" }, jsonc = { "biome" } },
  formatters = {
    biome = {
      args = { "format", "--indent-style", "space", "--stdin-file-path", "$FILENAME" },
    },
  },
})

require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("json-opts", { clear = true }),
    pattern = { "json", "json5", "jsonc" },
    callback = function()
      vim.opt_local.conceallevel = 0
    end,
  })
end)
