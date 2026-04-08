-- YAML: formatters, linters, custom filetypes.

-- Custom filetypes for GitHub Actions and Dependabot
vim.filetype.add({
  pattern = {
    [".*/%.github/dependabot.yml"] = "dependabot",
    [".*/%.github/dependabot.yaml"] = "dependabot",
    [".*/%.github/workflows[%w/]+.*%.yml"] = "gha",
    [".*/%.github/workflows/[%w/]+.*%.yaml"] = "gha",
  },
})

-- Use the yaml treesitter parser for custom filetypes
vim.treesitter.language.register("yaml", "gha")
vim.treesitter.language.register("yaml", "dependabot")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "gha", "dependabot" },
  callback = function(event)
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true

    -- Load yaml indent for custom filetypes that alias yaml
    if event.match ~= "yaml" then
      vim.cmd.runtime("indent/yaml.vim")
    end
  end,
})

require("conform").setup({
  formatters_by_ft = {
    yaml = { "yamlfmt" },
    gha = { "yamlfmt" },
    dependabot = { "yamlfmt" },
  },
  formatters = {
    yamlfmt = {
      prepend_args = {
        "-formatter",
        "retain_line_breaks_single=true",
        "-formatter",
        "pad_line_comments=2",
      },
    },
  },
})

require("lint").linters_by_ft.yaml = { "yamllint" }
require("lint").linters_by_ft.gha = { "actionlint" }

require("lint").linters.yamllint = vim.tbl_deep_extend("force", require("lint").linters.yamllint or {}, {
  args = {
    "--config-file",
    vim.env.DOTFILES .. "/extras/templates/.yamllint.yml",
    "--format",
    "parsable",
    "-",
  },
})

-- Defer SchemaStore catalog loading until a YAML file is opened.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "gha", "dependabot" },
  once = true,
  callback = function()
    vim.lsp.config("yamlls", {
      settings = {
        yaml = {
          schemas = require("schemastore").yaml.schemas(),
        },
      },
    })
  end,
})
