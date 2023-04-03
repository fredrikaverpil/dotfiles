return {

  -- change telescope config
  {
    "nvim-telescope/telescope.nvim",
    -- opts will be merged with the parent spec
    opts = {
      defaults = {
        file_ignore_patterns = { "^./.git/", "^node_modules/", "^poetry.lock" },
      },
    },
  },

}
