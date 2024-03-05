FORMATTERS_LUA = { 'stylua' }

return {

  { -- Autoformat
    'stevearc/conform.nvim',

    opts = function(_, opts)
      local formatters = require 'conform.formatters'
      formatters.stylua.args = vim.list_extend({ '--indent-type', 'Spaces', '--indent-width', '2' }, formatters.stylua.args)

      local remove_from_formatters = {}
      local extend_formatters_with = {}
      local replace_formatters_with = {
        lua = FORMATTERS_LUA,
      }

      -- NOTE: conform.nvim can use a sub-list to run only the first available formatter (see docs)

      -- remove from opts.formatters_by_ft
      for ft, formatters_ in pairs(remove_from_formatters) do
        opts.formatters_by_ft[ft] = vim.tbl_filter(function(formatter)
          return not vim.tbl_contains(formatters_, formatter)
        end, opts.formatters_by_ft[ft])
      end
      -- extend opts.formatters_by_ft
      for ft, formatters_ in pairs(extend_formatters_with) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        vim.list_extend(opts.formatters_by_ft[ft], formatters_)
      end
      -- replace opts.formatters_by_ft
      for ft, formatters_ in pairs(replace_formatters_with) do
        opts.formatters_by_ft[ft] = formatters_
      end
    end,
  },
}
