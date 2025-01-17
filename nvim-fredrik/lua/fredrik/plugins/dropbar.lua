return {

  {
    "Bekaboo/dropbar.nvim",
    enabled = false,
    event = "VeryLazy",
    -- optional, but required for fuzzy finder support
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      -- build = "make",
    },
    opts = {
      bar = {
        sources = function(buf, _)
          local sources = require("dropbar.sources")
          local utils = require("dropbar.utils")
          if vim.bo[buf].ft == "markdown" then
            return {
              sources.path,
              sources.markdown,
            }
          end
          if vim.bo[buf].buftype == "terminal" then
            return {
              sources.terminal,
            }
          end
          return {
            sources.path,
            utils.source.fallback({
              -- sources.lsp,
              sources.treesitter,
            }),
          }
        end,
      },
      icons = { kinds = { dir_icon = "", file_icon = "" } },
      sources = {
        path = {
          max_depth = 0,
        },
      },
    },
    config = function(_, opts)
      -- local dropbar_api = require("dropbar.api")
      -- vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
      -- vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
      -- vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })

      require("dropbar").setup(opts)
    end,
  },
}
