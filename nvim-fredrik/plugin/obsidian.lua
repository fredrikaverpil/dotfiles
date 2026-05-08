require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/obsidian-nvim/obsidian.nvim", version = vim.version.range("*") },
    { src = "https://github.com/folke/snacks.nvim", version = vim.version.range("*") }, -- sub-dependency
  })

  if vim.fn.has("mac") ~= 1 then
    return
  end

  local base = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents")
  local vaults = vim.tbl_filter(function(v)
    return vim.fn.isdirectory(v.path) == 1
  end, {
    { name = "personal", path = base .. "/personal" },
    { name = "work", path = base .. "/work" },
  })

  if #vaults == 0 then
    return
  end

  ---@param title string
  local function date_prefixed_id(title)
    return os.date("%Y-%m-%d") .. "-" .. title
  end

  require("obsidian").setup({
    workspaces = vaults,

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

  do
    local function find_vault(name)
      for _, v in ipairs(vaults) do
        if v.name == name then
          return v
        end
      end
    end

    local default = require("path").cwd_is_under("~/code/work") and find_vault("work") or find_vault("personal")
    if default then
      _G.Config.obsidian_vault = default
    end
  end

  local function pick_vault(callback)
    vim.ui.select(vaults, {
      prompt = "Select vault",
      format_item = function(v)
        local active = _G.Config.obsidian_vault and _G.Config.obsidian_vault.name == v.name
        return (active and "* " or "  ") .. v.name
      end,
    }, function(v)
      if not v then
        return
      end
      _G.Config.obsidian_vault = v
      vim.cmd("Obsidian workspace " .. v.name)
      if callback then
        callback(v)
      end
    end)
  end

  local function with_vault(callback)
    if _G.Config.obsidian_vault then
      callback(_G.Config.obsidian_vault)
    else
      pick_vault(callback)
    end
  end

  -- Keymaps
  vim.keymap.set("n", "<leader>nW", pick_vault, { desc = "Notes: switch vault" })

  vim.keymap.set("n", "<leader>ns", function()
    with_vault(function(v)
      ---@diagnostic disable-next-line: undefined-global
      Snacks.picker.grep({ dirs = { v.path } })
    end)
  end, { desc = "Notes: search text" })

  vim.keymap.set("n", "<leader>nf", function()
    with_vault(function(_)
      vim.cmd("Obsidian quick_switch")
    end)
  end, { desc = "Notes: search filenames" })

  vim.keymap.set("n", "<leader>nn", function()
    with_vault(function(_)
      vim.cmd("Obsidian new")
    end)
  end, { desc = "Notes: new" })

  vim.keymap.set("n", "<leader>nd", function()
    with_vault(function(_)
      vim.cmd("Obsidian today")
    end)
  end, { desc = "Notes: daily note" })

  vim.keymap.set("n", "<leader>nt", function()
    with_vault(function(_)
      vim.cmd("Obsidian new_from_template")
    end)
  end, { desc = "Notes: new from template" })

  vim.keymap.set("n", "<leader>nS", function()
    with_vault(function(v)
      vim.cmd.tabnew(v.path .. "/scratchpad.md")
    end)
  end, { desc = "Notes: scratchpad" })

  vim.keymap.set("n", "<leader>no", function()
    with_vault(function(v)
      vim.fn.jobstart({ "open", "obsidian://open?vault=" .. v.name })
    end)
  end, { desc = "Notes: open Obsidian" })
end)
