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
      require("lint").linters.protolint = {
        cmd = "protolint",
        stdin = false,
        append_fname = true,
        args = { "lint", "--reporter=json" },
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
