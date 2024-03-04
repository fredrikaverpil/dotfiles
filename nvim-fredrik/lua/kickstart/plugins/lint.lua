return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- NOTE: linters are expected to be set up by separate language plugins,
      -- see e.g. lang_go.lua.
      local lint = require 'lint'
      lint.linters_by_ft = lint.linters_by_ft or {}

      -- WARN: enabled by default, so let's disable them, unless language
      -- plugins are defined and sets them up. This means if a language plugin
      -- sets the linter up, we have to comment out the override here.
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      lint.linters_by_ft['clojure'] = nil
      lint.linters_by_ft['dockerfile'] = nil
      lint.linters_by_ft['inko'] = nil
      lint.linters_by_ft['janet'] = nil
      lint.linters_by_ft['json'] = nil
      lint.linters_by_ft['markdown'] = nil
      lint.linters_by_ft['rst'] = nil
      lint.linters_by_ft['ruby'] = nil
      lint.linters_by_ft['terraform'] = nil
      lint.linters_by_ft['text'] = nil

      -- local ensure_installed = {}
      -- for filetype, linters in pairs(lint.linters_by_ft) do
      --   for index, linter in ipairs(linters) do
      --     table.insert(ensure_installed, linter)
      --   end
      -- end
      -- -- TODO: install ensure_installed with mason

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          require('lint').try_lint()
        end,
      })
    end,
  },
}
