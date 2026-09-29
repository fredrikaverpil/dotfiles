if Config.use_arborist then
  require("lazyload").on_vim_enter(function()
    vim.pack.add({
      { src = "https://github.com/arborist-ts/arborist.nvim", version = vim.version.range("*") },
    })

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

    local opts = {
      install_popular = false,
      update_cadence = "weekly",
      overrides = {},
    }

    for lang, p in pairs(custom_parsers) do
      require("merge")(opts, { overrides = { [lang] = p.install_info } })

      vim.treesitter.language.register(lang, p.filetype)
    end

    require("arborist").setup(opts)
  end)
end
