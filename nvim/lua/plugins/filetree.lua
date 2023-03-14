return {

  -- change neo-tree config
  {
    "nvim-neo-tree/neo-tree.nvim",
    -- opts will be merged with the parent spec
    opts = {
      filesystem = {
        filtered_items = {
          visible = true, -- when true, they will just be displayed differently than normal items
          hide_dotfiles = false,
          hide_gitignored = true,
        },
      },
    },
  },
}
