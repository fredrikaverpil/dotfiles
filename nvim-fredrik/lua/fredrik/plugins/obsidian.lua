local M = {}
M.vault_path = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/fredrik")
M.notes_path = vim.fn.expand(M.vault_path .. "/Meeting_notes")
M.scratchpad_path = vim.fn.expand(M.vault_path .. "/scratchpad.md")

---@param title string
local function zettelkasten_id(title)
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
end

---@param title string
local function title_id(title)
  return title
end

---@param title string
local function meeting_note_id(title)
  return os.date("%Y-%m-%d") .. "-" .. title
end

return {
  -- "epwalsh/obsidian.nvim",
  "obsidian-nvim/obsidian.nvim",
  enabled = function()
    -- only enable on macOS for now, and if vault_path exists
    return vim.fn.has("mac") == 1 and vim.fn.isdirectory(M.vault_path) == 1
  end,
  version = "*",
  ft = "markdown",
  dependencies = {},

  ---@module 'obsidian'
  ---@type obsidian.config
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

    daily_notes = {
      folder = "Daily",
    },

    attachments = {
      folder = "./", -- same folder as current file
    },

    templates = {
      folder = "_templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      -- A map for custom variables, the key should be the variable and the value a function
      substitutions = {},
      customizations = {
        ["meeting_notes"] = {
          notes_subdir = "Meeting notes",
          -- note_id_func = zettelkasten_id,
          note_id_func = meeting_note_id,
        },
      },
    },

    -- note_id_func = zettelkasten_id,
    note_id_func = title_id,

    legacy_commands = false,
  },
  keys = require("fredrik.config.keymaps").setup_obsidian_keymaps(M),
  cmd = { "Obsidian" },
}
