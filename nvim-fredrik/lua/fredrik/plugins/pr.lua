return {
  {
    "fredrikaverpil/pr.nvim",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    dir = "~/code/public/pr.nvim",

    ---@type PR.Config
    -- opts = {
    --   github_token = function()
    --     local cmd = { "op", "read", "op://Personal/github.com/tokens/pr.nvim", "--no-newline" }
    --     local obj = vim.system(cmd, { text = true }):wait()
    --     if obj.code ~= 0 then
    --       vim.notify("Failed to get token from 1Password", vim.log.levels.ERROR)
    --       return nil
    --     end
    --     return obj.stdout
    --   end,
    -- },

    keys = {
      {
        "<leader>gbv",
        function()
          require("pr").view()
        end,
        desc = "View PR in browser",
      },
    },
    cmd = { "PRView" },
  },
}
