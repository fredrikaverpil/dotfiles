return {

  -- nvim-cmp configuration so to not preselect completion and require tab to select
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      opts = nil,
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      -- local has_words_before = function()
      --   unpack = unpack or table.unpack
      --   local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      --   return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      -- end

      local luasnip = require("luasnip")
      local cmp = require("cmp")

      -- opts.mapping = cmp.mapping.preset.insert(vim.tbl_deep_extend("force", opts.mapping, {
      --   ["<CR>"] = vim.NIL,
      -- }))
      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<CR>"] = vim.NIL,
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })
            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
            -- they way you will only jump inside the snippet region
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          -- elseif has_words_before() then
          --   cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })
      opts.preselect = cmp.PreselectMode.None
    end,
  },
}