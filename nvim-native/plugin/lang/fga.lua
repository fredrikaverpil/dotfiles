vim.filetype.add({
  extension = {
    fga = "fga",
  },
})

-- Register tree-sitter-fga parser for syntax highlighting (requires nvim-treesitter)
local ts_ok, ts_parsers = pcall(require, "nvim-treesitter.parsers")
if ts_ok then
  local parser_config = {
    install_info = {
      url = "https://github.com/matoous/tree-sitter-fga",
      branch = "main",
      generate = false,
      queries = "queries",
    },
  }

  ts_parsers.fga = parser_config

  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = function()
      require("nvim-treesitter.parsers").fga = parser_config
    end,
  })
end
