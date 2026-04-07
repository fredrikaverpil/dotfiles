-- obsidian.nvim: Obsidian vault integration.

local vault_path = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/fredrik")
local scratchpad_path = vault_path .. "/scratchpad.md"

-- Only enable on macOS if the vault exists.
if vim.fn.has("mac") ~= 1 or vim.fn.isdirectory(vault_path) ~= 1 then
  return
end

vim.pack.add({
  { src = "https://github.com/obsidian-nvim/obsidian.nvim" },
})

---@param title string
local function date_prefixed_id(title)
  return os.date("%Y-%m-%d") .. "-" .. title
end

require("obsidian").setup({
  workspaces = {
    {
      name = "personal",
      path = vault_path,
    },
  },

  completion = {
    nvim_cmp = false,
    blink = true,
    min_chars = 2,
  },

  picker = {
    name = "snacks.pick",
  },

  daily_notes = {
    folder = "Daily",
    template = vault_path .. "/_templates/daily.md",
  },

  attachments = {
    folder = "./",
  },

  templates = {
    folder = "_templates",
    date_format = "%Y-%m-%d",
    time_format = "%H:%M",
    substitutions = {},
    customizations = {
      ["meeting_notes"] = {
        notes_subdir = "Meeting notes",
        note_id_func = date_prefixed_id,
      },
    },
  },

  note_id_func = date_prefixed_id,
  frontmatter = {
    enabled = true,
    sort = false,
    func = function(note)
      local frontmatter = note.frontmatter(note)
      frontmatter.id = note.id
      if frontmatter.tags == nil then
        frontmatter.tags = {}
      end
      if frontmatter.categories == nil then
        frontmatter.categories = {}
      end
      return frontmatter
    end,
  },

  ui = { enable = false },
  legacy_commands = false,
})

-- Keymaps
local nmap = function(lhs, rhs, opts)
  vim.keymap.set("n", lhs, rhs, opts)
end

nmap("<leader>ns", function()
  Snacks.picker.grep({ cwd = vault_path })
end, { desc = "Notes: search text" })
nmap("<leader>nf", "<cmd>Obsidian quick_switch<cr>", { desc = "Notes: search filenames" })
nmap("<leader>nn", "<cmd>Obsidian new<cr>", { desc = "Notes: new" })
nmap("<leader>nd", "<cmd>Obsidian today<cr>", { desc = "Notes: daily note" })
nmap("<leader>nt", "<cmd>Obsidian new_from_template<cr>", { desc = "Notes: new from template" })
nmap("<leader>nS", function()
  vim.cmd("tabnew " .. scratchpad_path)
end, { desc = "Notes: scratchpad" })
