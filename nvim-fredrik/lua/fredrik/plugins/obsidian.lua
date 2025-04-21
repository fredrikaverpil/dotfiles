local M = {}
M.vault_path = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/fredrik")
M.notes_path = vim.fn.expand(M.vault_path .. "/Meeting_notes")
M.scratchpad_path = vim.fn.expand(M.vault_path .. "/scratchpad.md")

return {
  -- "epwalsh/obsidian.nvim",
  "obsidian-nvim/obsidian.nvim",
  lazy = true,
  dependencies = {
    -- required
    "nvim-lua/plenary.nvim",

    -- optional
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",

    {
      "saghen/blink.cmp",
      dependencies = {
        { "saghen/blink.compat", branch = "main" },
      },
      -- opts = {
      --   sources = {
      --     default = { "obsidian", "obsidian_new", "obsidian_tags" },
      --     providers = {
      --       obsidian = {
      --         name = "obsidian",
      --         module = "blink.compat.source",
      --       },
      --       obsidian_new = {
      --         name = "obsidian_new",
      --         module = "blink.compat.source",
      --       },
      --       obsidian_tags = {
      --         name = "obsidian_tags",
      --         module = "blink.compat.source",
      --       },
      --     },
      --   },
      -- },
      -- opts_extend = {
      --   "sources.default",
      -- },
    },
  },
  enabled = function()
    -- only enable on macOS for now, and if vault_path exists
    return vim.fn.has("mac") == 1 and vim.fn.isdirectory(M.vault_path) == 1
  end,
  version = "*",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
  --   "BufReadPre path/to/my-vault/**.md",
  --   "BufNewFile path/to/my-vault/**.md",
  -- },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = M.vault_path,
      },
    },

    -- Optional, completion of wiki links, local markdown links, and tags using nvim-cmp.
    completion = {
      nvim_cmp = false, -- NOTE: use blink.cmp instead
      blink = true,
      -- Trigger completion at 2 chars.
      min_chars = 2,
    },

    picker = {
      name = "snacks.pick",
    },

    -- Specify how to handle attachments.
    attachments = {
      -- The default folder to place images in via `:ObsidianPasteImg`.
      -- If this is a relative path it will be interpreted as relative to the vault root.
      -- You can always override this per image by passing a full path to the command instead of just a filename.
      img_folder = "Files",
      -- A function that determines the text to insert in the note when pasting an image.
      -- It takes two arguments, the `obsidian.Client` and an `obsidian.Path` to the image file.
      -- This is the default implementation.
      ---@param client obsidian.Client
      ---@param path obsidian.Path the absolute path to the image file
      ---@return string
      img_text_func = function(client, path)
        path = client:vault_relative_path(path) or path
        return string.format("![%s](%s)", path.name, path)
      end,
    },

    templates = {
      folder = "Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      -- A map for custom variables, the key should be the variable and the value a function
      substitutions = {},
    },

    note_id_func = function(title)
      -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
      -- In this case a note with the title 'My new note' will be given an ID that looks
      -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
      local suffix = ""
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. "-" .. suffix
    end,
  },
  keys = require("fredrik.config.keymaps").setup_obsidian_keymaps(M),
  cmd = { "ObsidianSearch", "ObsidianQuickSwitch", "ObsidianNew" },
}
