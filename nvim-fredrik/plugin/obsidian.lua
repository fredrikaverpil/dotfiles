require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/obsidian-nvim/obsidian.nvim" },
    { src = "https://github.com/folke/snacks.nvim" }, -- sub-dependency
  })

  local vault_path = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/fredrik")
  local scratchpad_path = vault_path .. "/scratchpad.md"

  -- Only enable on macOS if the vault exists.
  if vim.fn.has("mac") ~= 1 or vim.fn.isdirectory(vault_path) ~= 1 then
    return
  end

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
  vim.keymap.set("n", "<leader>ns", function()
    Snacks.picker.grep({ cwd = vault_path })
  end, { desc = "Notes: search text" })
  vim.keymap.set("n", "<leader>nf", function()
    vim.cmd("Obsidian quick_switch")
  end, { desc = "Notes: search filenames" })
  vim.keymap.set("n", "<leader>nn", function()
    vim.cmd("Obsidian new")
  end, { desc = "Notes: new" })
  vim.keymap.set("n", "<leader>nd", function()
    vim.cmd("Obsidian today")
  end, { desc = "Notes: daily note" })
  vim.keymap.set("n", "<leader>nt", function()
    vim.cmd("Obsidian new_from_template")
  end, { desc = "Notes: new from template" })
  vim.keymap.set("n", "<leader>nS", function()
    vim.cmd("tabnew " .. scratchpad_path)
  end, { desc = "Notes: scratchpad" })
end)
