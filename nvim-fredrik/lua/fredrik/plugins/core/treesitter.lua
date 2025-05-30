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
      local parser_name = vim.treesitter.language.get_lang(filetype) -- might return filetype (not helpful)
      if not parser_name then
        return
      end
      -- Try to get existing parser (helpful check if filetype was returned above)
      local parser_configs = require("nvim-treesitter.parsers")
      if not parser_configs[parser_name] then
        return -- Parser not available, skip silently
      end

      local parser_installed = pcall(vim.treesitter.get_parser, bufnr, parser_name)

      if not parser_installed then
        -- If not installed, install parser synchronously
        require("nvim-treesitter").install({ parser_name }):wait(30000)
      end

      -- let's check again
      parser_installed = pcall(vim.treesitter.get_parser, bufnr, parser_name)

      if parser_installed then
        -- Start treesitter for this buffer
        vim.treesitter.start(bufnr, parser_name)
      end
    end,
  })
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    event = "BufRead",
    branch = "main",
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
