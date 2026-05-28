require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://codeberg.org/mfussenegger/nvim-lint" },
  })

  local lint = require("lint")

  -- linters_by_ft and per-linter config aggregated from plugin/lang/*.lua via
  -- require("lang").register().
  lint.linters_by_ft = require("lang").linters_by_ft()
  -- Shallow merge: each config field (e.g. args) replaces the builtin wholesale,
  -- matching direct `lint.linters.<name>.<field> = ...` assignment. A deep merge
  -- would positionally merge list values like args and leak trailing defaults.
  for name, cfg in pairs(require("lang").linter_configs()) do
    lint.linters[name] = vim.tbl_extend("force", lint.linters[name] or {}, cfg)
  end

  vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
    group = vim.api.nvim_create_augroup("lint", { clear = true }),
    callback = function()
      lint.try_lint()
    end,
  })

  -- Imperative per-language lint wiring (dynamic cwd, custom autocmds) lives in
  -- plugin/lang/*.lua via the lint_setup hook.
  for _, setup in ipairs(require("lang").lint_setups()) do
    setup(lint)
  end

  -- Lint already-open buffers (initial file was read before VimEnter)
  lint.try_lint()
end)
