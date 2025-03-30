vim.api.nvim_create_autocmd("FileType", {
  pattern = { "proto" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = false

    vim.opt_local.colorcolumn = "120" -- TODO: what does the buf formatter use?
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

--- Cached filepath to buf.yaml.
local cached_buf_config_filepath = nil

--- Return the filepath to buf.yaml.
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
local function buf_lint_cwd()
  return vim.fn.fnamemodify(buf_config_filepath(), ":h")
end

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

local function buf_lint_setup()
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
  -- HACK: cannot pass in cwd as function (for lazy loading). Instead, an autocmd is used.
  -- opts.linters["buf_lint"] = {
  --   args = buf_lint_args,
  --   -- cwd = buf_lint_cwd, -- requires https://github.com/mfussenegger/nvim-lint/pull/674
  --   append_fname = false,
  -- }
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    pattern = { "*.proto" },
    callback = function()
      require("lint").try_lint("buf_lint", {
        args = buf_lint_args,
        cwd = buf_lint_cwd(),
        append_fname = false,
      })
    end,
  })
end

local function api_linter_setup()
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
  -- HACK: cannot pass in cwd as function (for lazy loading). Instead, an autocmd is used.
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    pattern = { "*.proto" },
    callback = function()
      require("lint").try_lint("api_linter", {
        cwd = buf_lint_cwd(),
      })
    end,
  })
end

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
    opts = function(_, opts)
      -- NOTE: buf_lint and api-linter is not part of linters_by_ft:
      -- * buf_lint is executed below in an autocmd, because workaround for lazy-loaded cwd is desired.
      -- * api_linter is not yet merged into nvim-lint: https://github.com/mfussenegger/nvim-lint/pull/665

      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters = opts.linters or {}

      opts.linters_by_ft["proto"] = { "protolint" }
      local protolint_config_file = require("fredrik.utils.environ").getenv("DOTFILES") .. "/templates/.protolint.yaml" -- FIXME: make this into the fallback filepath.
      local protolint_args = { "lint", "--reporter=json", "--config_path=" .. protolint_config_file }
      opts.linters["protolint"] = { args = protolint_args }

      buf_lint_setup()
      api_linter_setup()
    end,
  },

  {
    "virtual-lsp-config",
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
          vim.list_extend(opts.ensure_installed, { "buf_ls" })
        end,
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        buf_ls = {
          -- lsp: https://github.com/bufbuild/buf
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/protols.lua
          cmd = { "buf", "beta", "lsp", "--timeout=0", "--log-format=text" },
          filetypes = { "proto" },
          root_markers = { "buf.yaml", "buf.yml", ".git" },
          settings = {
            buf_ls = {},
          },
        },
      },
    },
  },
}
