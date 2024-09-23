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

      -- custom protolint config file reading
      -- see: https://github.com/mfussenegger/nvim-lint#custom-linters
      local protolint_config_file = vim.fn.expand("$DOTFILES/templates/.protolint.yaml")
      local protolint_args = { "lint", "--reporter=json", "--config_path=" .. protolint_config_file }
      opts.linters["protolint"] = { args = protolint_args }

      -- custom buf_lint config file reading
      local buf_config_file = require("utils.find").find_file("buf.yaml")
      local buf_args = require("lint").linters.buf_lint.args -- defaults
      if buf_config_file then
        vim.notify_once("Found file: " .. buf_config_file, vim.log.levels.INFO)
        require("utils.defaults").buf_config_path = buf_config_file
        buf_args = {
          "lint",
          "--error-format",
          "json",
          "--config",
          buf_config_file,
        }
      end
      opts.linters["buf_lint"] = { args = buf_args }

      local os_path_sep = package.config:sub(1, 1) -- "/" on Unix, "\" on Windows

      --- Find a file upwards in the directory tree and return its path, if found.
      --- @param filename string
      --- @param start_path string
      --- @return string | nil
      local function file_upwards(filename, start_path)
        -- Ensure start_path is a directory
        local start_dir = vim.fn.isdirectory(start_path) == 1 and start_path or vim.fn.fnamemodify(start_path, ":h")
        local home_dir = vim.fn.expand("$HOME")

        while start_dir ~= home_dir do
          -- logger.debug("Searching for " .. filename .. " in " .. start_dir)

          local try_path = start_dir .. os_path_sep .. filename
          if vim.fn.filereadable(try_path) == 1 then
            -- logger.debug("Found " .. filename .. " at " .. try_path)
            return try_path
          end

          -- Go up one directory
          start_dir = vim.fn.fnamemodify(start_dir, ":h")
        end

        return nil
      end

      -- custom api-linter
      require("lint").linters.api_linter = {
        name = "api_linter",
        cmd = "api-linter",
        stdin = false,
        append_fname = true,
        args = {
          "--output-format=json",

          function()
            -- local buffer_filepath = vim.fn.expand("%:p")
            local buffer_parent_dir = vim.fn.expand("%:p:h")

            local buf_config_filepath = file_upwards("buf.yaml", buffer_parent_dir)
            if buf_config_filepath == nil then
              error("Buf config file (buf.yaml) not found")
            end
            local buf_config_folderpath = vim.fn.fnamemodify(buf_config_filepath, ":h")
            local descriptor_filepath = buf_config_folderpath .. "/descriptor-set.pb"

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

          function()
            local buffer_parent_dir = vim.fn.expand("%:p:h")
            local apilinter_config_filepath = file_upwards("api-linter.yaml", buffer_parent_dir)
            if apilinter_config_filepath == nil then
              error("API linter (api-linter.yaml) config file not found")
            end

            -- TODO: actually find the config
            return "--config=" .. apilinter_config_filepath
          end,
        },
        stream = "stdout",
        ignore_exitcode = true,
        env = nil,
        parser = function(output)
          -- vim.notify("parsing api-linter output")
          -- vim.notify(vim.inspect(output))
          if output == "" then
            return {}
          end
          local json_output = vim.json.decode(output)
          -- vim.notify(vim.inspect(json_output))
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
                col = problem.location.start_position.column_number,
                end_lnum = problem.location.end_position.line_number - 1,
                end_col = problem.location.end_position.column_number,
              })
            end
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
