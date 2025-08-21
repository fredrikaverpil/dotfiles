vim.api.nvim_create_autocmd("FileType", {
  pattern = { "fga" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
    vim.opt_local.colorcolumn = "80"
  end,
})

--- Returns the path to the VSCode extension server for FGA.
--- NOTE: to make it available;
--- 1. git clone https://github.com/openfga/vscode-ext fga-vscode-ext
--- 2. npm install
--- 3. npm run compile
local function vscode_ext_path()
  local path = vim.fn.expand("~/code/public/fga-vscode-ext/server/out/server.node.js")
  if not vim.fn.filereadable(path) then
    vim.notify("FGA VSCode extension server not found at " .. path, vim.log.levels.WARN)
  end
  return path
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      -- Configure the custom FGA parser before treesitter loads
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      if not parser_config.fga then
        parser_config.fga = {
          install_info = {
            url = "https://github.com/matoous/tree-sitter-fga",
            files = { "src/parser.c" },
            branch = "main",
            generate_requires_npm = false,
            requires_generate_from_grammar = false,
          },
          filetype = "fga",
        }
      end
    end,
    opts = {
      ensure_installed = {
        fga = "fga",
      },
    },
    opts_extend = {
      "ensure_installed",
    },
  },

  {
    "virtual-lsp-config",
    dependencies = {},
    opts = {
      servers = {
        fga = {
          mason = false, -- do not attempt LSP installation via mason
          cmd = { "node", vscode_ext_path(), "--stdio" },
          filetypes = { "fga" },
          root_markers = { ".git" },
          settings = {
          },
        },
      },
    },
  },
}
