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

local function get_relative_path(file, cwd)
  -- Ensure both paths end with `/` for consistency
  if not cwd:sub(-1) == "/" then
    cwd = cwd .. "/"
  end

  -- Find the starting position of the relative path
  local start, stop = file:find(cwd, 1, true)

  -- If `cwd` is found at the beginning of `file`, slice the path
  if start == 1 then
    local relative_path = file:sub(stop + 1)
    if relative_path:sub(1, 1) == "/" then
      relative_path = relative_path:sub(2)
    end
    return relative_path
  else
    return file -- or handle error / return nil if needed
  end
end

return {

  {
    "stevearc/conform.nvim",
    event = "VeryLazy",
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
    event = "VeryLazy",
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
      opts.linters_by_ft["proto"] = { "buf_lint", "protolint", "api_linter" } -- TODO: use official api-linter once merged: https://github.com/mfussenegger/nvim-lint/pull/665

      --- Return the filepath to buf.yaml.
      local cached_buf_config_filepath = nil
      local function buf_config_filepath()
        if cached_buf_config_filepath ~= nil then
          return cached_buf_config_filepath
        end
        local buffer_parent_dir = vim.fn.expand("%:p:h") -- the path to the folder of the opened .proto file.
        local buf_config_filepaths = vim.fs.find(
          { "buf.yaml", "buf.yml" },
          { path = buffer_parent_dir, upward = true, type = "file", limit = 1, stop = vim.fs.normalize("~") }
        )
        if #buf_config_filepaths == 0 then
          error("Buf config file not found")
        end
        cached_buf_config_filepath = buf_config_filepaths[1]
        vim.notify("buf config file found: " .. cached_buf_config_filepath)
        return cached_buf_config_filepath
      end

      -- custom buf_lint config file reading
      -- local buf_args = require("lint").linters.buf_lint.args -- defaults
      local function buf_lint_cwd()
        return vim.fn.fnamemodify(buf_config_filepath(), ":h")
      end
      local buf_lint_args = {
        "lint",
        "--error-format=json",
        -- NOTE: if setting the cwd to the same directory as the buf.yaml,
        -- the `--config` argument is not needed.
        -- function()
        --   return "--config=" .. buf_config_filepath()
        -- end,
        function()
          -- NOTE: append the relative proto filepath. Only works if the
          -- cwd is set to the buf.yaml directory.
          local bufpath = vim.fn.expand("%:p")
          local bufpath_rel = get_relative_path(bufpath, buf_lint_cwd())
          vim.notify("buf_lint is using bufpath: " .. bufpath_rel)
          return bufpath_rel
        end,
      }
      opts.linters["buf_lint"] = {
        args = buf_lint_args,
        cwd = buf_lint_cwd,
        append_fname = false, -- NOTE: must append the relative proto filepath from cwd (of buf.yaml).
      }

      -- custom protolint config file reading
      local protolint_config_file = vim.fn.expand("$DOTFILES/templates/.protolint.yaml") -- FIXME: make this into the fallback filepath.
      local protolint_args = { "lint", "--reporter=json", "--config_path=" .. protolint_config_file }
      opts.linters["protolint"] = { args = protolint_args }

      --- custom linter for api-linter.
      local descriptor_filepath = os.tmpname()
      local cleanup_descriptor = function()
        os.remove(descriptor_filepath)
      end
      --- Function to set the `--descriptor-set-in` argument.
      --- This requires the buf CLI, which will first build the descriptor file.
      local function descriptor_set_in()
        if vim.fn.executable("buf") == 0 then
          error("buf CLI not found")
        end
        local buf_config_folderpath = vim.fn.fnamemodify(buf_config_filepath(), ":h")
        local buf_cmd = { "buf", "build", "-o", descriptor_filepath }
        local buf_cmd_opts = { cwd = buf_config_folderpath }
        local obj = vim.system(buf_cmd, buf_cmd_opts):wait()
        if obj.code ~= 0 then
          error("Command failed: " .. vim.inspect(buf_cmd) .. "\n" .. obj.stderr)
        end
        local descriptor_arg = "--descriptor-set-in=" .. descriptor_filepath
        return descriptor_arg
      end
      require("lint").linters.api_linter = {
        name = "api_linter", -- NOTE: differentiate from the name of the linter in nvim-lint.
        cmd = "api-linter",
        stdin = false,
        append_fname = true,
        args = {
          "--output-format=json",
          "--disable-rule=core::0191::java-multiple-files",
          "--disable-rule=core::0191::java-package",
          "--disable-rule=core::0191::java-outer-classname",
          descriptor_set_in,
        },
        stream = "stdout",
        ignore_exitcode = true,
        env = nil,
        parser = function(output, bufnr, linter_cwd)
          vim.notify("api-linter is using cwd: " .. linter_cwd)
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
