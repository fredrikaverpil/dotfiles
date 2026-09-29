if Config.use_nvim_treesitter then
  require("lazyload").on_vim_enter(function()
    vim.api.nvim_create_autocmd("PackChanged", {
      callback = function(ev)
        if ev.data.spec.name == "nvim-treesitter" then
          vim.cmd("TSUpdate")
        end
      end,
    })

    vim.pack.add({
      { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
      { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
    })

    -- Custom parsers not shipped with nvim-treesitter.
    local custom_parsers = {
      godoc = {
        filetype = "godoc",
        install_info = {
          url = "https://github.com/fredrikaverpil/tree-sitter-godoc",
          branch = "main",
          generate = false,
          queries = "queries",
        },
      },
      fga = {
        filetype = "fga",
        install_info = {
          url = "https://github.com/matoous/tree-sitter-fga",
          branch = "main",
          generate = false,
          queries = "queries",
        },
      },
    }

    for lang, p in pairs(custom_parsers) do
      vim.treesitter.language.register(lang, p.filetype)
    end

    local function inject_custom_parsers()
      local parsers = require("nvim-treesitter.parsers")
      for lang, p in pairs(custom_parsers) do
        parsers[lang] = { install_info = p.install_info }
      end
    end

    inject_custom_parsers()

    vim.api.nvim_create_autocmd("User", {
      pattern = "TSUpdate",
      callback = inject_custom_parsers,
    })

    require("lazyload").on_vim_enter(function()
      require("treesitter-context").setup({
        multiwindow = true,
      })
    end)

    --- Sign parser .so on macOS to prevent code-signature crashes.
    ---@param parser_name string
    local function sign_parser_macos(parser_name)
      if vim.fn.has("mac") ~= 1 then
        return
      end
      local parser_path = vim.fn.stdpath("data") .. "/site/parser/" .. parser_name .. ".so"
      if vim.fn.filereadable(parser_path) == 1 then
        vim.fn.system({ "codesign", "--force", "--sign", "-", parser_path })
      end
    end

    --- Install a parser via nvim-treesitter.
    ---@param lang string parser/language name
    ---@return boolean success
    local function install_parser(lang)
      if not Config.use_nvim_treesitter then
        return false
      end
      local parsers = require("nvim-treesitter.parsers")
      if not parsers[lang] then
        return false
      end
      require("nvim-treesitter").install({ lang }):wait(30000)
      sign_parser_macos(lang)
      return true
    end

    --- Auto-start treesitter highlighting for every buffer.
    --- Registered at plugin/ sourcing time (step 11) so it runs before LSP's
    --- FileType handlers (registered at VimEnter), preventing race conditions
    --- with plugins that use treesitter queries on LspAttach.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
      callback = function(event)
        local bufnr = event.buf
        local ft = event.match
        if ft == "" then
          return
        end

        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
          return
        end

        local ok = pcall(vim.treesitter.start, bufnr, lang)
        if ok then
          return
        end

        if install_parser(lang) then
          pcall(vim.treesitter.start, bufnr, lang)
        end
      end,
    })
  end)
end
