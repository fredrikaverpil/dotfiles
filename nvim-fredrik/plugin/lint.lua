-- nvim-lint stays eager because plugin/lang/protobuf.lua wires up custom
-- linters via require("lint").linters and a BufEnter autocmd that fires before
-- VimEnter when a .proto file is on the command line.
vim.pack.add({
  { src = "https://codeberg.org/mfussenegger/nvim-lint" },
})

require("lazyload").on_vim_enter(function()
  local lint = require("lint")

  lint.linters_by_ft = {
    dockerfile = { "hadolint" },
    gha = { "actionlint" },
    go = { "golangcilint" },
    markdown = { "markdownlint" },
    proto = { "protolint" },
    python = { "mypy" },
    sh = { "shellcheck" },
    terraform = { "terraform_validate", "tflint" },
    tf = { "terraform_validate", "tflint" },
    yaml = { "yamllint" },
  }

  lint.linters.markdownlint.args = {
    "--config",
    vim.env.DOTFILES .. "/extras/templates/.markdownlint.json",
    "--stdin",
  }
  lint.linters.protolint.args = {
    "lint",
    "--reporter=json",
    "--config_path=" .. vim.env.DOTFILES .. "/extras/templates/.protolint.yaml",
  }
  lint.linters.yamllint.args = {
    "--config-file",
    vim.env.DOTFILES .. "/extras/templates/.yamllint.yml",
    "--format",
    "parsable",
    "-",
  }

  vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
    group = vim.api.nvim_create_augroup("native-nvim-lint", { clear = true }),
    callback = function()
      lint.try_lint()
    end,
  })

  -- Lint already-open buffers (initial file was read before VimEnter)
  lint.try_lint()
end)
