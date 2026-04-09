local registry = require("registry")

registry.add({
  lsp_servers = { "buf_ls" },
  mason_ensure_installed = { "buf", "protolint", "api-linter" },
  conform = {
    formatters_by_ft = { proto = { "buf" } },
  },
  lint = {
    linters_by_ft = { proto = { "protolint" } },
    linters = {
      protolint = {
        args = {
          "lint",
          "--reporter=json",
          "--config_path=" .. vim.env.DOTFILES .. "/extras/templates/.protolint.yaml",
        },
      },
    },
  },
})

-- Helpers for buf_lint and api_linter

local function get_relative_path(file, cwd)
  if not cwd:sub(-1) == "/" then
    cwd = cwd .. "/"
  end
  local start, stop = file:find(cwd, 1, true)
  if start == 1 then
    local relative_path = file:sub(stop + 1)
    if relative_path:sub(1, 1) == "/" then
      relative_path = relative_path:sub(2)
    end
    return relative_path
  else
    return file
  end
end

local cached_buf_config_filepath = nil

local function buf_config_filepath()
  if cached_buf_config_filepath ~= nil then
    return cached_buf_config_filepath
  end
  local buffer_parent_dir = vim.fn.expand("%:p:h")
  local found = vim.fs.find(
    { "buf.yaml", "buf.yml" },
    { path = buffer_parent_dir, upward = true, type = "file", limit = 1, stop = vim.fs.normalize("~") }
  )
  if #found == 0 then
    error("Buf config file not found")
  end
  cached_buf_config_filepath = found[1]
  return cached_buf_config_filepath
end

local function buf_lint_cwd()
  return vim.fn.fnamemodify(buf_config_filepath(), ":h")
end

-- buf_lint: custom autocmd because cwd must be dynamic
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("native-buf-lint", { clear = true }),
  pattern = { "*.proto" },
  callback = function()
    local buf_lint_args = {
      "lint",
      "--error-format=json",
      function()
        local bufpath = vim.fn.expand("%:p")
        return get_relative_path(bufpath, buf_lint_cwd())
      end,
    }
    require("lint").try_lint("buf_lint", {
      args = buf_lint_args,
      cwd = buf_lint_cwd(),
      append_fname = false,
    })
  end,
})

-- api_linter: custom linter definition + autocmd
local descriptor_filepath = os.tmpname()

local function descriptor_set_in()
  if vim.fn.executable("buf") == 0 then
    error("buf CLI not found")
  end
  local buf_config_folderpath = vim.fn.fnamemodify(buf_config_filepath(), ":h")
  local obj = vim.system({ "buf", "build", "-o", descriptor_filepath }, { cwd = buf_config_folderpath }):wait()
  if obj.code ~= 0 then
    error("buf build failed: " .. obj.stderr)
  end
  return "--descriptor-set-in=" .. descriptor_filepath
end

if vim.fn.executable("api-linter") == 1 then
  registry.add({
    lint = {
      linters = {
        api_linter = {
          name = "api_linter",
          cmd = "api-linter",
          stdin = false,
          append_fname = false,
          args = {
            "--output-format=json",
            "--disable-rule=core::0191::java-multiple-files",
            "--disable-rule=core::0191::java-package",
            "--disable-rule=core::0191::java-outer-classname",
            function()
              return descriptor_set_in()
            end,
            function()
              local bufpath = vim.fn.expand("%:p")
              return get_relative_path(bufpath, buf_lint_cwd())
            end,
          },
          stream = "stdout",
          ignore_exitcode = true,
          parser = function(output)
            if output == "" then
              return {}
            end

            local ok, json_output = pcall(vim.json.decode, output)
            if not ok then
              error("Failed to parse api-linter output: " .. output)
            end

            local diagnostics = {}
            for _, item in ipairs(json_output) do
              for _, problem in ipairs(item.problems or {}) do
                table.insert(diagnostics, {
                  message = problem.message,
                  code = problem.rule_id .. " " .. problem.rule_doc_uri,
                  severity = vim.diagnostic.severity.WARN,
                  lnum = problem.location.start_position.line_number - 1,
                  col = problem.location.start_position.column_number - 1,
                  end_lnum = problem.location.end_position.line_number - 1,
                  end_col = problem.location.end_position.column_number - 1,
                })
              end
            end

            os.remove(descriptor_filepath)
            return diagnostics
          end,
        },
      },
    },
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("native-api-linter", { clear = true }),
    pattern = { "*.proto" },
    callback = function()
      require("lint").try_lint("api_linter", {
        cwd = buf_lint_cwd(),
      })
    end,
  })
end
