-- local logging = require("fredrik.utils.logging") -- NOTE: commented out, only used by custom api-linter impl

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "proto" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = false
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

local function api_linter_buf_setup()
  -- Use api_linter_buf from nvim-lint PR #665
  local api_linter_buf = require("lint.linters.api_linter_buf")

  -- Add disable rules for Java-related warnings (not using Java codegen)
  local original_args = api_linter_buf.args
  api_linter_buf.args = {
    "--output-format=json",
    "--disable-rule=core::0191::java-multiple-files",
    "--disable-rule=core::0191::java-package",
    "--disable-rule=core::0191::java-outer-classname",
  }
  for _, arg in ipairs(original_args) do
    if type(arg) == "function" then
      table.insert(api_linter_buf.args, arg)
    end
  end

  api_linter_buf.register_autocmd()
end

return {
  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "mason-org/mason.nvim",
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
        "mason-org/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "buf", "protolint", "api-linter" })
        end,
      },
    },
    opts = function(_, opts)
      -- NOTE: buf_lint and api-linter is not part of linters_by_ft:
      -- * buf_lint is executed below in an autocmd, because workaround for lazy-loaded cwd is desired.
      -- * api_linter_buf uses its own autocmd via register_autocmd()

      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters = opts.linters or {}

      opts.linters_by_ft["proto"] = { "protolint" }
      local protolint_config_file = require("fredrik.utils.environ").getenv("DOTFILES")
        .. "/extras/templates/.protolint.yaml" -- FIXME: make this into the fallback filepath.
      local protolint_args = { "lint", "--reporter=json", "--config_path=" .. protolint_config_file }
      opts.linters["protolint"] = { args = protolint_args }

      buf_lint_setup()
      api_linter_buf_setup()
    end,
  },

  {
    "virtual-lsp-config",
    dependencies = {
      {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
          {
            "mason-org/mason.nvim",
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
          cmd = { "buf", "lsp", "serve", "--timeout=0", "--log-format=text" },
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
