if Config.use_arborist then
  require("lazyload").on_vim_enter(function()
    vim.g.arborist_loaded = true -- skip auto-setup, we're configuring manually, because custom parsers

    vim.pack.add({
      "https://github.com/arborist-ts/arborist.nvim",
    })

    local custom_parsers = {
      {
        lang = "fga",
        register = { "fga", "fga" },
        config = {
          install_info = {
            url = "https://github.com/matoous/tree-sitter-fga",
            branch = "main",
            generate = false,
            queries = "queries",
          },
        },
      },
      {
        lang = "godoc",
        register = { "godoc", "godoc" },
        config = {
          install_info = {
            url = "https://github.com/fredrikaverpil/tree-sitter-godoc",
            branch = "main",
            generate = false,
            queries = "queries",
          },
        },
      },
    }

    local opts = {
      install_popular = false,
      overrides = {},
    }

    for _, p in ipairs(custom_parsers) do
      local install_info = p.config.install_info
      require("merge")(opts, { overrides = { [p.lang] = install_info } })

      vim.treesitter.language.register(unpack(p.register))
    end

    require("arborist").setup(opts)

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

        -- ignore certain filetypes
        for _, prefix in ipairs({ "snacks_", "blink-" }) do
          if vim.startswith(ft, prefix) then
            return
          end
        end

        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
          return
        end

        local ok = pcall(vim.treesitter.start, bufnr, lang)
        if ok then
          return
        end

        ok = pcall(vim.cmd(":ArboristInstall " .. lang))
        if not ok then
          return
        end

        ok = pcall(vim.treesitter.start, bufnr, lang)
      end,
    })
  end)
end
