return {
  {
    "nvim-mini/mini.diff",
    event = "VeryLazy",
    version = "*",
    opts = {
      view = {
        style = "sign",
        signs = {
          add = "▎",
          change = "▎",
          delete = "",
        },
      },
    },
    keys = {
      {
        "<leader>go",
        function()
          require("mini.diff").toggle_overlay(0)
        end,
        desc = "Toggle mini.diff overlay",
      },
      {
        "<leader>ghr",
        function()
          require("mini.diff").do_hunks(0, "reset", {})
        end,
        desc = "Reset hunk",
      },
      {
        "<leader>gha",
        function()
          require("mini.diff").do_hunks(0, "apply", {})
        end,
        desc = "Apply (stage) hunk",
      },
      {
        "<leader>ghy",
        function()
          require("mini.diff").do_hunks(0, "yank", {})
        end,
        desc = "Yank hunk",
      },
      {
        "<leader>ghb",
        function()
          local default_branch = require("fredrik.utils.git").get_default_branch()
          local file = vim.api.nvim_buf_get_name(0)
          local relative_path = vim.fn.fnamemodify(file, ":~:.")

          -- Get content from the default branch
          local content = vim.fn.system("git show " .. default_branch .. ":" .. relative_path)

          if vim.v.shell_error == 0 then
            local lines = vim.split(content, "\n")
            require("mini.diff").set_ref_text(0, lines)
            vim.notify("Diff base changed to " .. default_branch, vim.log.levels.INFO)
          else
            vim.notify("Could not get file from " .. default_branch, vim.log.levels.ERROR)
          end
        end,
        desc = "Change base to default branch",
      },
      {
        "<leader>ghB",
        function()
          require("mini.diff").set_ref_text(0, {})
          vim.notify("Diff base reset to Git index", vim.log.levels.INFO)
        end,
        desc = "Reset base to Git index",
      },
    },
  },
}
