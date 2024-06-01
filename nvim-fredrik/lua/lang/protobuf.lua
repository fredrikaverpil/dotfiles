vim.api.nvim_create_autocmd("FileType", {
  pattern = { "proto" },
  callback = function()
    -- set proto specific options
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.colorcolumn = "80"
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
          vim.list_extend(opts.ensure_installed, { "buf" })
        end,
      },
    },
    ft = { "proto" },
    opts = {
      formatters_by_ft = {
        proto = { "buf" },
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
          vim.list_extend(opts.ensure_installed, { "buf", "protolint" })
        end,
      },
    },
    ft = { "proto" },
    opts = function(_, opts)
      opts.linters_by_ft["proto"] = { "buf_lint", "protolint" }

      -- custom protolint definition
      -- see: https://github.com/mfussenegger/nvim-lint#custom-linters
      local protolint_config_file = vim.fn.expand("$DOTFILES/templates/.protolint.yaml")
      -- vim.notify_once("Found file: " .. protolint_config_file, vim.log.levels.INFO)
      require("lint").linters.protolint = {
        name = "protolint",
        cmd = "protolint",
        stdin = false,
        append_fname = true,
        args = { "lint", "--reporter=json", "--config_path=" .. protolint_config_file },
        stream = "stderr",
        ignore_exitcode = true,
        env = nil,
        parser = function(output)
          if output == "" then
            return {}
          end
          local json_output = vim.json.decode(output)
          local diagnostics = {}
          if json_output.lints == nil then
            return diagnostics
          end
          for _, item in ipairs(json_output.lints) do
            table.insert(diagnostics, {
              lnum = item.line - 1,
              col = item.column - 1,
              message = item.message,
              file = item.filename,
              code = item.rule,
              severity = vim.diagnostic.severity.WARN,
            })
          end
          return diagnostics
        end,
      }

      -- custom buf_lint config file reading
      local args = require("lint").linters.buf_lint.args -- defaults
      local buf_config_file = require("utils.find").find_file("buf.yaml")
      if buf_config_file then
        vim.notify_once("Found file: " .. buf_config_file, vim.log.levels.INFO)
        require("utils.defaults").buf_config_path = buf_config_file
        args = {
          "lint",
          "--error-format",
          "json",
          "--config",
          buf_config_file,
        }
      end
      opts.linters["buf_lint"] = { args = args }
    end,
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
          vim.list_extend(opts.ensure_installed, { "bufls" })
        end,
      },
    },
    ft = { "proto" },
    opts = {
      servers = {
        bufls = {},
      },
    },
  },
}
