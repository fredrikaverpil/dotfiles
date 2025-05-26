return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    event = "BufRead",
    branch = "main",
    build = ":TSUpdate",
    ---@class TSConfig
    opts = {
      -- custom handling of parsers can be done like this:
      -- ensure_installed = { parser = { filetype1, filetype2 } }
      ensure_installed = {},
    },
    config = function(buf, opts)
      require("fredrik.config.options").treesitter_foldexpr()

      -- debugging
      -- vim.notify(vim.inspect(opts.ensure_installed))

      local already_installed = require("nvim-treesitter.config").installed_parsers()

      -- install parsers from custom opts.ensure_installed
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

      -- Auto-install and start parsers for any buffer
      vim.api.nvim_create_autocmd({ "BufRead", "FileType" }, {
        callback = function(event)
          local bufnr = event.buf
          local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

          -- Skip if no filetype
          if filetype == "" then
            return
          end

          -- Check if this filetype is already handled by explicit opts.ensure_installed config
          for _, filetypes in pairs(opts.ensure_installed) do
            local ft_table = type(filetypes) == "table" and filetypes or { filetypes }
            if vim.tbl_contains(ft_table, filetype) then
              return -- Already handled above
            end
          end

          -- Get parser name based on filetype
          local parser_name = vim.treesitter.language.get_lang(filetype)
          if not parser_name then
            vim.notify(vim.inspect("No treesitter parser found for filetype: " .. filetype), vim.log.levels.WARN)
            return
          end

          -- Try to get existing parser
          local parser_configs = require("nvim-treesitter.parsers")
          if not parser_configs[parser_name] then
            return -- Parser not available, skip silently
          end

          local parser_exists = pcall(vim.treesitter.get_parser, bufnr, parser_name)

          if not parser_exists then
            -- check if parser is already installed
            if vim.tbl_contains(already_installed, parser_name) then
              vim.notify("Parser for " .. parser_name .. " already installed.", vim.log.levels.INFO)
            else
              -- If not installed, install parser synchronously
              vim.notify("Installing parser for " .. parser_name, vim.log.levels.INFO)
              require("nvim-treesitter").install({ parser_name }):wait(300000) -- wait max. 5 minutes
            end
          end

          -- Start treesitter for this buffer
          vim.treesitter.start(bufnr, parser_name)
        end,
      })
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
