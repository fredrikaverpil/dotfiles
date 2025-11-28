vim.api.nvim_create_autocmd("FileType", {
  pattern = { "fga" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- Register FGA filetype
vim.filetype.add({
  extension = {
    fga = "fga",
  },
})

-- Configure the custom FGA parser
-- Must register BOTH in User TSUpdate (for installation) AND immediately (for buffer opening)
local parser_config = {
  ---@type InstallInfo
  install_info = {
    url = "https://github.com/matoous/tree-sitter-fga",
    branch = "main", -- will use latest commit from main branch
    generate = false, -- only needed if repo does not contain pre-generated `src/parser.c`
    queries = "queries", -- also install queries from given directory
  },
}

-- Register immediately so it's available when buffers open
require("nvim-treesitter.parsers").fga = parser_config

-- Also register on TSUpdate for installation; required for auto-install
vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  callback = function()
    require("nvim-treesitter.parsers").fga = parser_config
  end,
})

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      opts.ensure_installed.fga = "fga"
    end,
  },
}
