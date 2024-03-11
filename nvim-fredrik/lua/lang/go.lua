local find_file = function(filename)
  local command = "fd --hidden --no-ignore '" .. filename .. "' " .. vim.fn.getcwd() .. " | head -n 1"
  local file = io.popen(command):read("*l")
  return file and file or nil
end

local use_golangci_config_if_available = function(linters)
  local config_file = find_file(".golangci.yml")
  if config_file then
    vim.notify = require("notify")
    vim.notify("Using golangci-lint config: " .. config_file)
    return {
      "run",
      "--out-format",
      "json",
      "--config",
      config_file,
      function()
        return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
      end,
    }
  else
    return linters.golangcilint.args
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.colorcolumn = "120"
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
          vim.list_extend(opts.ensure_installed, { "gofumpt", "goimports", "gci", "golines" })
        end,
      },
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    opts = {
      formatters_by_ft = {
        go = { "gofumpt", "goimports", "gci", "golines" },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "golangci-lint" })
        end,
      },
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    opts = {
      linters_by_ft = {
        go = { "golangci-lint" },
      },
      linters = {
        golangcilint = {
          args = use_golangci_config_if_available(require("lint").linters),
        },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
          {
            "williamboman/mason.nvim",
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "gopls" })
        end,
      },
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    opts = {
      inlay_hints = {
        enabled = false,
      },
      servers = {
        gopls = {},
      },
    },
  },
}
