vim.pack.add({ { src = "https://codeberg.org/mfussenegger/nvim-lint", name = "nvim-lint" } })

require("defer").on_vim_enter(function()
  local registry = require("registry")
  local lint = require("lint")

  lint.linters_by_ft = registry.lint.linters_by_ft or {}

  for name, config in pairs(registry.lint.linters or {}) do
    lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name] or {}, config)
  end

  local timer = vim.uv.new_timer()
  local function debounced_lint()
    timer:start(100, 0, function()
      timer:stop()
      vim.schedule(function()
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)
        if #names == 0 then
          vim.list_extend(names, lint.linters_by_ft["_"] or {})
        end
        vim.list_extend(names, lint.linters_by_ft["*"] or {})

        names = vim.tbl_filter(function(linter_name)
          return lint.linters[linter_name] ~= nil
        end, names)

        if #names > 0 then
          lint.try_lint(names)
        end
      end)
    end)
  end

  vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
    group = vim.api.nvim_create_augroup("native-nvim-lint", { clear = true }),
    callback = debounced_lint,
  })

  -- Lint already-open buffers (initial file was read before VimEnter)
  debounced_lint()
end)
