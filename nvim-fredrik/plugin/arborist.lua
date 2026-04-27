if Config.use_arborist then
  require("lazyload").on_vim_enter(function()
    vim.pack.add({
      { src = "https://github.com/arborist-ts/arborist.nvim", version = vim.version.range("*") },
    })

    local custom_parsers = {
      {
        lang = "fga",
        filetype = "fga",
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
        filetype = "godoc",
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
      update_cadence = "weekly",
      overrides = {},
    }

    for _, p in ipairs(custom_parsers) do
      local install_info = p.config.install_info
      require("merge")(opts, { overrides = { [p.lang] = install_info } })

      vim.treesitter.language.register(p.lang, p.filetype)
    end

    require("arborist").setup(opts)
  end)
end
