if Config.use_arborist then
  require("lazyload").on_vim_enter(function()
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
      update_cadencey = "weekly",
      overrides = {},
    }

    for _, p in ipairs(custom_parsers) do
      local install_info = p.config.install_info
      require("merge")(opts, { overrides = { [p.lang] = install_info } })

      vim.treesitter.language.register(unpack(p.register))
    end

    require("arborist").setup(opts)
  end)
end
