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
      opts.linters_by_ft["proto"] = { "buf_lint", "protolint", "api_linter" }

      -- buf config location
      local buffer_parent_dir = vim.fn.expand("%:p:h")
      local buf_config_filepath = require("utils.find").find_file_upwards({ "buf.yaml", "buf.yml" }, buffer_parent_dir)

      -- custom protolint config file reading
      local protolint_config_file = vim.fn.expand("$DOTFILES/templates/.protolint.yaml") -- FIXME: make this into the fallback filepath.
      local protolint_args = { "lint", "--reporter=json", "--config_path=" .. protolint_config_file }
      opts.linters["protolint"] = { args = protolint_args }

      -- custom buf_lint config file reading
      local buf_args = require("lint").linters.buf_lint.args -- defaults
      if buf_config_filepath then
        require("utils.defaults").buf_config_path = buf_config_filepath
        buf_args = {
          "lint",
          "--error-format",
          "json",
          "--config",
          buf_config_filepath,
        }
      end
      opts.linters["buf_lint"] = { args = buf_args }

      --- custom linter for api-linter.
      local descriptor_filepath = os.tmpname()
      local cleanup_descriptor = function()
        os.remove(descriptor_filepath)
      end
      require("lint").linters.api_linter = {
        name = "api_linter",
        cmd = "api-linter",
        stdin = false,
        append_fname = true,
        args = {
          "--output-format=json",

          -- function to get the --descriptor-set-in argument
          function()
            if buf_config_filepath == nil then
              error("Buf config file (buf.yaml) not found")
            end
            local buf_config_folderpath = vim.fn.fnamemodify(buf_config_filepath, ":h")
            local buf_cmd = { "buf", "build", "-o", descriptor_filepath }
            local buf_cmd_opts = { cwd = buf_config_folderpath }
            local obj = vim.system(buf_cmd, buf_cmd_opts):wait()
            if obj.code ~= 0 then
              vim.notify(vim.inspect(obj))
              error("Command failed: " .. buf_cmd)
            end
            local descriptor_arg = "--descriptor-set-in=" .. descriptor_filepath
            return descriptor_arg
          end,

          -- function to get the --config argument.
          function()
            local config_filenames = {
              -- NOTE: could be regexp but this is likely faster.
              "api-linter.yaml",
              "api-linter.yml",
              "api-lint.yaml",
              "api-lint.yml",
              "apilinter.yaml",
              "apilinter.yml",
              "apilint.yaml",
              "apilint.yml",
            }
            local apilinter_config_filepath = require("utils.find").find_file_upwards(config_filenames, buffer_parent_dir)
            if apilinter_config_filepath == nil then
              error("API linter (api-linter.yaml) config file not found")
            end

            return "--config=" .. apilinter_config_filepath
          end,
        },
        stream = "stdout",
        ignore_exitcode = true,
        env = nil,
        parser = function(output)
          if output == "" then
            return {}
          end
          local json_output = vim.json.decode(output)
          local diagnostics = {}
          if json_output == nil then
            return diagnostics
          end
          for _, item in ipairs(json_output) do
            for _, problem in ipairs(item.problems) do
              table.insert(diagnostics, {
                message = problem.message,
                file = item.file,
                code = problem.rule_id .. " " .. problem.rule_doc_uri,
                severity = vim.diagnostic.severity.WARN,
                lnum = problem.location.start_position.line_number - 1,
                col = problem.location.start_position.column_number - 1,
                end_lnum = problem.location.end_position.line_number - 1,
                end_col = problem.location.end_position.column_number - 1,
              })
            end
          end
          cleanup_descriptor()
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
