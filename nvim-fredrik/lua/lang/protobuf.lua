local function find_file(filename, excluded_dirs)
  if not excluded_dirs then
    excluded_dirs = { ".git", "node_modules", ".venv" }
  end
  local exclude_str = ""
  for _, dir in ipairs(excluded_dirs) do
    exclude_str = exclude_str .. " --exclude " .. dir
  end
  local command = "fd --hidden --no-ignore" .. exclude_str .. " '" .. filename .. "' " .. vim.fn.getcwd() .. " | head -n 1"
  local file = io.popen(command):read("*l")
  local path = file and file or nil

  if path ~= nil then
    require("utils.defaults").notifications.proto[filename].path = path
  end

  return path
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "proto" },
  callback = function()
    -- set proto specific options
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.colorcolumn = "120"

    -- show notification if proto is found
    local notifications = require("utils.defaults").notifications.proto
    if notifications["buf.yaml"].path and not notifications._emitted then
      vim.notify_once("Using buf.yaml config: " .. notifications["buf.yaml"].path, vim.log.levels.INFO)
      notifications._emitted = true
    end
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
      require("lint").linters.protolint = {
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
      local buf_config_file = find_file("buf.yaml")
      if buf_config_file ~= nil then
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
