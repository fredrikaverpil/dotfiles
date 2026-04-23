require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://codeberg.org/mfussenegger/nvim-lint" },
  })

  local lint = require("lint")

  lint.linters_by_ft = {
    dockerfile = { "hadolint" },
    gha = { "actionlint" },
    go = { "golangcilint" },
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
      -- Per-config descriptor state: { path, dirty, building, pending = {cb...} }
      local descriptor_state = {}

      local function state_for(cfg)
        local s = descriptor_state[cfg]
        if s == nil then
          s = { path = os.tmpname(), dirty = true, building = false, pending = {} }
          descriptor_state[cfg] = s
        end
        return s
      end

      local build_descriptor

      build_descriptor = function(cfg)
        local s = state_for(cfg)
        s.building = true
        s.dirty = false
        vim.system(
          { "buf", "build", "-o", s.path },
          { cwd = vim.fn.fnamemodify(cfg, ":h") },
          vim.schedule_wrap(function(obj)
            s.building = false
            if obj.code ~= 0 then
              s.dirty = true
              s.pending = {} -- drop queued callbacks; they'll retrigger on the next event
              vim.notify("buf build failed: " .. tostring(obj.stderr or ""), vim.log.levels.WARN)
              return
            end
            if s.dirty then
              -- A write came in during build; rebuild. Callbacks stay queued.
              build_descriptor(cfg)
              return
            end
            local pending = s.pending
            s.pending = {}
            for _, cb in ipairs(pending) do
              cb()
            end
          end)
        )
      end

      local function ensure_descriptor(cfg, callback)
        local s = state_for(cfg)
        if not s.dirty and not s.building then
          callback()
          return
        end
        table.insert(s.pending, callback)
        if not s.building then
          build_descriptor(cfg)
        end
      end

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("lint-api-linter-cleanup", { clear = true }),
        callback = function()
          for _, s in pairs(descriptor_state) do
            os.remove(s.path)
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
            return "--descriptor-set-in=" .. state_for(buf_config_filepath()).path
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
        callback = function(args)
          local cfg = buf_config_filepath()
          if cfg == nil then
            return
          end
          local cwd = vim.fn.fnamemodify(cfg, ":h")
          if args.event == "BufWritePost" then
            state_for(cfg).dirty = true
          end
          ensure_descriptor(cfg, function()
            if not vim.api.nvim_buf_is_valid(args.buf) then
              return
            end
            vim.api.nvim_buf_call(args.buf, function()
              lint.try_lint("api_linter", { cwd = cwd })
            end)
          end)
        end,
      })
    end
  end

  -- Lint already-open buffers (initial file was read before VimEnter)
  lint.try_lint()
end)
