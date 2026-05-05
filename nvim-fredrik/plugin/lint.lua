require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://codeberg.org/mfussenegger/nvim-lint" },
  })

  local lint = require("lint")

  lint.linters_by_ft = {
    dockerfile = { "hadolint" },
    gha = { "actionlint" },
    markdown = { "markdownlint" },
    proto = { "protolint" },
    python = { "mypy" },
    sh = { "shellcheck" },
    terraform = { "terraform_validate", "tflint" },
    tf = { "terraform_validate", "tflint" },
    yaml = { "yamllint" },
  }

  lint.linters.markdownlint.args = {
    "--config",
    vim.env.DOTFILES .. "/extras/templates/.markdownlint.json",
    "--stdin",
  }
  lint.linters.protolint.args = {
    "lint",
    "--reporter=json",
    "--config_path=" .. vim.env.DOTFILES .. "/extras/templates/.protolint.yaml",
  }
  lint.linters.yamllint.args = {
    "--config-file",
    vim.env.DOTFILES .. "/extras/templates/.yamllint.yml",
    "--format",
    "parsable",
    "-",
  }

  vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
    group = vim.api.nvim_create_augroup("lint", { clear = true }),
    callback = function()
      lint.try_lint()
    end,
  })

  -- protobuf: buf_lint + api_linter (custom autocmds because cwd must be dynamic)
  do
    local buf_config_cache = {}

    local function buf_config_filepath()
      local buffer_parent_dir = vim.fn.expand("%:p:h")
      local cached = buf_config_cache[buffer_parent_dir]
      if cached == false then
        return nil
      end
      if cached then
        return cached
      end
      local found = vim.fs.find(
        { "buf.yaml", "buf.yml" },
        { path = buffer_parent_dir, upward = true, type = "file", limit = 1, stop = vim.fs.normalize("~") }
      )
      if #found == 0 then
        buf_config_cache[buffer_parent_dir] = false
        return nil
      end
      buf_config_cache[buffer_parent_dir] = found[1]
      return found[1]
    end

    local function buf_lint_cwd()
      local cfg = buf_config_filepath()
      if cfg == nil then
        return nil
      end
      return vim.fn.fnamemodify(cfg, ":h")
    end

    local function get_relative_path(file, cwd)
      if cwd:sub(-1) ~= "/" then
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

    -- buf_lint
    lint.linters.buf_lint.args = {
      "lint",
      "--error-format=json",
      function()
        return get_relative_path(vim.fn.expand("%:p"), buf_lint_cwd())
      end,
    }
    lint.linters.buf_lint.append_fname = false

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = vim.api.nvim_create_augroup("lint-buf", { clear = true }),
      pattern = { "*.proto" },
      callback = function()
        local cwd = buf_lint_cwd()
        if cwd == nil then
          return
        end
        lint.try_lint("buf_lint", { cwd = cwd })
      end,
    })

    -- api_linter
    if vim.fn.executable("api-linter") == 1 and vim.fn.executable("buf") == 1 then
      local descriptor_paths = {}

      local function descriptor_path_for(cfg)
        if descriptor_paths[cfg] == nil then
          descriptor_paths[cfg] = os.tmpname()
        end
        return descriptor_paths[cfg]
      end

      local function descriptor_set_in()
        local cfg = assert(buf_config_filepath(), "buf config not found")
        local path = descriptor_path_for(cfg)
        local obj = vim.system({ "buf", "build", "-o", path }, { cwd = vim.fn.fnamemodify(cfg, ":h") }):wait()
        if obj.code ~= 0 then
          error("buf build failed: " .. tostring(obj.stderr or ""))
        end
        return "--descriptor-set-in=" .. path
      end

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("lint-api-linter-cleanup", { clear = true }),
        callback = function()
          for _, p in pairs(descriptor_paths) do
            os.remove(p)
          end
        end,
      })

      lint.linters.api_linter = {
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
            return get_relative_path(vim.fn.expand("%:p"), buf_lint_cwd())
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

          return diagnostics
        end,
      }

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("lint-api-linter", { clear = true }),
        pattern = { "*.proto" },
        callback = function()
          local cwd = buf_lint_cwd()
          if cwd == nil then
            return
          end
          lint.try_lint("api_linter", { cwd = cwd })
        end,
      })
    end
  end

  -- go: golangcilint with cwd at the nearest go.mod (handles nested modules)
  do
    local go_mod_dir_cache = {}

    local function go_mod_dir()
      local buffer_parent_dir = vim.fn.expand("%:p:h")
      local cached = go_mod_dir_cache[buffer_parent_dir]
      if cached == false then
        return nil
      end
      if cached then
        return cached
      end
      local found = vim.fs.find(
        { "go.mod" },
        { path = buffer_parent_dir, upward = true, type = "file", limit = 1, stop = vim.fs.normalize("~") }
      )
      if #found == 0 then
        go_mod_dir_cache[buffer_parent_dir] = false
        return nil
      end
      local dir = vim.fn.fnamemodify(found[1], ":h")
      go_mod_dir_cache[buffer_parent_dir] = dir
      return dir
    end

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
      group = vim.api.nvim_create_augroup("lint-go", { clear = true }),
      pattern = { "*.go" },
      callback = function()
        local cwd = go_mod_dir()
        if cwd == nil then
          return
        end
        lint.try_lint("golangcilint", { cwd = cwd })
      end,
    })
  end

  -- Lint already-open buffers (initial file was read before VimEnter)
  lint.try_lint()
end)
