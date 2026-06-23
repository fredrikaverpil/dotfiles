require("lazyload").on_vim_enter(function()
  -- Vaults live in iCloud; don't even install the plugin elsewhere.
  if vim.fn.has("mac") ~= 1 then
    return
  end

  vim.pack.add({
    { src = "https://github.com/obsidian-nvim/obsidian.nvim", version = vim.version.range("*") },
    { src = "https://github.com/folke/snacks.nvim", version = vim.version.range("*") }, -- sub-dependency
  })

  local icloud = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents")
  local vaults = {
    personal = { path = vim.fs.joinpath(icloud, "personal") },
    work = { path = vim.fs.joinpath(icloud, "work") },
  }

  ---@param title string
  local function date_prefixed_id(title)
    return os.date("%Y-%m-%d") .. "-" .. title
  end

  require("obsidian").setup({
    workspaces = vim.tbl_values(vaults),

    picker = {
      name = "snacks.pick",
    },

    daily_notes = {
      folder = "Daily",
      template = "daily.md",
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

  -- The vault follows the cwd: work notes under ~/code/work, personal elsewhere.
  -- Re-evaluated on every keymap so changing directory changes the vault.
  local function vault_for_cwd()
    if require("path").cwd_is_under("~/code/work") then
      return "work"
    else
      return "personal"
    end
  end

  -- Obsidian commands act on the *active* workspace, so align it with the cwd
  -- before running them; otherwise notes land in the wrong vault. The active
  -- workspace defaults to the first one (vaults live in iCloud, so cwd never
  -- matches a vault path). Guarded to avoid obsidian's "Already in workspace"
  -- notification on every keypress.
  local function in_vault(action)
    local name = vault_for_cwd()
    ---@diagnostic disable-next-line: undefined-global
    if Obsidian.workspace.name ~= name then
      vim.cmd("Obsidian workspace " .. name)
    end
    action(vaults[name], name)
  end

  -- Keymaps
  vim.keymap.set("n", "<leader>ns", function()
    in_vault(function(vault)
      ---@diagnostic disable-next-line: undefined-global
      Snacks.picker.grep({ dirs = { vault.path } })
    end)
  end, { desc = "Notes: search text" })

  vim.keymap.set("n", "<leader>nf", function()
    in_vault(function()
      vim.cmd("Obsidian quick_switch")
    end)
  end, { desc = "Notes: search filenames" })

  vim.keymap.set("n", "<leader>nn", function()
    in_vault(function()
      vim.cmd("Obsidian new")
    end)
  end, { desc = "Notes: new" })

  vim.keymap.set("n", "<leader>nd", function()
    in_vault(function()
      vim.cmd("Obsidian today")
    end)
  end, { desc = "Notes: daily note" })

  vim.keymap.set("n", "<leader>nt", function()
    in_vault(function()
      vim.cmd("Obsidian new_from_template")
    end)
  end, { desc = "Notes: new from template" })

  vim.keymap.set("n", "<leader>nS", function()
    in_vault(function(vault)
      vim.cmd.tabnew(vim.fs.joinpath(vault.path, "scratchpad.md"))
    end)
  end, { desc = "Notes: scratchpad" })

  vim.keymap.set("n", "<leader>no", function()
    in_vault(function(_, name)
      vim.fn.jobstart({ "open", "obsidian://open?vault=" .. name })
    end)
  end, { desc = "Notes: open Obsidian" })
end)
