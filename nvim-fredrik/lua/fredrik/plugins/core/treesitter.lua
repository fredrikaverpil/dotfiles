local branch = "master"

--- Register parsers from opts.ensure_installed
local function register(ensure_installed)
  for filetype, parser in pairs(ensure_installed) do
    local filetypes = vim.treesitter.language.get_filetypes(parser)
    if not vim.tbl_contains(filetypes, filetype) then
      table.insert(filetypes, filetype)
    end

    -- register and start parsers for filetypes
    vim.treesitter.language.register(parser, filetypes)
  end
end

--- Install and start parsers for nvim-treesitter.
local function install_and_start()
  -- Auto-install and start treesitter parser for any buffer with a registered filetype
  vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    callback = function(event)
      local bufnr = event.buf
      local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

      -- Skip if no filetype
      if filetype == "" then
        return
      end

      -- Get parser name based on filetype
      local parser_name = vim.treesitter.language.get_lang(filetype) -- WARNING: might return filetype (not helpful)
      if not parser_name then
        -- vim.notify(
        --   "Filetype " .. vim.inspect(filetype) .. " has no parser registered",
        --   vim.log.levels.WARN,
        --   { title = "core/treesitter" }
        -- )
        return
      end

      -- vim.notify(
      --   vim.inspect("Successfully got parser " .. parser_name .. " for filetype " .. filetype),
      --   vim.log.levels.DEBUG,
      --   { title = "core/treesitter" }
      -- )

      -- Check if parser_name is available in parser configs
      local parser_configs = require("nvim-treesitter.parsers")
      local parser_can_be_used = nil
      if branch == "master" then
        parser_can_be_used = parser_configs.list[parser_name]
      elseif branch == "main" then
        parser_can_be_used = parser_configs[parser_name]
      end
      if not parser_can_be_used then
        -- vim.notify(
        --   "Parser config does not have parser " .. vim.inspect(parser_name) .. ", skipping",
        --   vim.log.levels.WARN,
        --   { title = "core/treesitter" }
        -- )
        return -- Parser not ailable, skip silently
      end

      local parser_installed = pcall(vim.treesitter.get_parser, bufnr, parser_name)

      -- If not installed, install parser synchronously
      if not parser_installed then
        if branch == "master" then
          vim.cmd("TSInstallSync " .. parser_name)
        elseif branch == "main" then
          require("nvim-treesitter").install({ parser_name }):wait(30000) -- main branch syntax
        end
        -- vim.notify("Installed parser: " .. parser_name, vim.log.levels.INFO, { title = "core/treesitter" })
      end

      -- Check so tree-sitter can see the newly installed parser
      parser_installed = pcall(vim.treesitter.get_parser, bufnr, parser_name)
      if not parser_installed then
        vim.notify(
          "Failed to get parser for " .. parser_name .. " after installation",
          vim.log.levels.WARN,
          { title = "core/treesitter" }
        )
        return
      end

      -- Start treesitter for this buffer
      vim.treesitter.start(bufnr, parser_name)
    end,
  })
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    event = "BufRead",
    branch = branch, -- master to be frozen
    build = ":TSUpdate",
    ---@class TSConfig
    opts = {
      -- Other plugins can pass in desired filetype/parser combos.
      -- ensure_installed = { filetype = "parser1", filetype2 = "parser2" },
      ensure_installed = {},
    },
    config = function(_, opts)
      -- Set up folding via tree-sitter (will be overridden by LSP settings, when LSP supports folding).
      require("fredrik.config.options").treesitter_foldexpr()

      -- Register parsers from opts.ensure_installed
      register(opts.ensure_installed)

      -- Create autocmd which installs and starts parsers.
      install_and_start()

      -- debugging
      -- vim.notify(vim.inspect(opts.ensure_installed))
      -- local already_installed = require("nvim-treesitter.config").installed_parsers()
      -- vim.notify(vim.inspect(already_installed))
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
