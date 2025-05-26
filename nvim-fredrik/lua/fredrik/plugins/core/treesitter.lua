return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    event = "BufRead",
    branch = "main",
    build = ":TSUpdate",
    ---@class TSConfig
    opts = {
      ensure_installed = {
        -- parser = { filetype1, filetype2, ... }
        diff = { "diff" },
        regex = { "regex" },
        http = { "http" },
      },
    },
    config = function(buf, opts)
      require("fredrik.config.options").treesitter_foldexpr()

      -- debugging
      -- vim.notify(vim.inspect(opts.ensure_installed))

      -- install parsers
      local parsers = vim.tbl_keys(opts.ensure_installed)
      require("nvim-treesitter").install(parsers)

      -- register and start parsers for filetypes
      for parser, filetypes in pairs(opts.ensure_installed) do
        vim.treesitter.language.register(parser, filetypes)

        vim.api.nvim_create_autocmd({ "FileType" }, {
          pattern = filetypes,
          callback = function(event)
            vim.treesitter.start(event.buf)
          end,
        })
      end
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufRead",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      event = "BufRead",
    },
    opts = {
      multiwindow = true,
    },
  },
}
