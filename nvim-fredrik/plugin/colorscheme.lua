vim.pack.add({
  { src = "https://github.com/afonsofrancof/OSC11.nvim" },
  { src = "https://github.com/zenbones-theme/zenbones.nvim", version = vim.version.range("*") },
}, { load = false })

vim.g.bones_compat = 1 -- use built-in vim highlight API, not lush.nvim

-- Set colorscheme.
do
  local function set_dark()
    vim.o.background = "dark"
    vim.cmd.colorscheme("zenbones")
  end

  local function set_light()
    vim.o.background = "light"
    vim.cmd.colorscheme("zenbones")
  end

  if vim.o.background == "light" then
    set_light()
  else
    set_dark()
  end

  require("osc11").setup({
    on_dark = set_dark,
    on_light = set_light,
  })
end

-- Zenbones highlight overrides
do
  local colors = require("colors")

  local function apply_overrides()
    if not vim.g.colors_name then -- Zenbones sets g.colors_name
      return
    end

    -- Extract palette from terminal colors set by zenbones
    local palette = {
      bg = vim.g.terminal_color_0,
      rose = vim.g.terminal_color_1,
      leaf = vim.g.terminal_color_2,
      wood = vim.g.terminal_color_3,
      water = vim.g.terminal_color_4,
      blossom = vim.g.terminal_color_5,
      sky = vim.g.terminal_color_6,
      fg = vim.g.terminal_color_7,
      bg1 = vim.g.terminal_color_8,
      rose1 = vim.g.terminal_color_9,
      leaf1 = vim.g.terminal_color_10,
      wood1 = vim.g.terminal_color_11,
      water1 = vim.g.terminal_color_12,
      blossom1 = vim.g.terminal_color_13,
      sky1 = vim.g.terminal_color_14,
      fg1 = vim.g.terminal_color_15,
    }

    if not palette.bg then
      return
    end

    ---@param group string
    ---@param opts table
    local function hl(group, opts)
      vim.api.nvim_set_hl(0, group, opts)
    end

    -- Cursor contrast with background
    hl("Cursor", { fg = palette.bg, bg = palette.fg })
    hl("TermCursor", { fg = palette.bg, bg = palette.fg })

    hl("Cursorword", { bg = colors.blend(palette.bg, palette.bg1, 90), underline = false })

    -- Neotest
    hl("NeotestPassed", { fg = palette.leaf })
    hl("NeotestFailed", { fg = palette.rose })
    hl("NeotestRunning", { fg = palette.wood })
    hl("NeotestSkipped", { fg = palette.sky })
    hl("NeotestFile", { fg = palette.sky })
    hl("NeotestDir", { fg = palette.water })
    hl("NeotestNamespace", { fg = palette.blossom })
    hl("NeotestFocused", { bold = true, underline = true })
    hl("NeotestAdapterName", { fg = palette.rose })
    hl("NeotestWinSelect", { fg = palette.sky, bold = true })
    hl("NeotestMarked", { fg = palette.wood, bold = true })
    hl("NeotestTarget", { fg = palette.rose })
    hl("NeotestUnknown", { fg = colors.blend(palette.bg, palette.fg, 50) })
    hl("NeotestExpandMarker", { fg = colors.blend(palette.bg, palette.fg, 50) })

    -- Snacks notifier
    hl("SnacksNotifierBorderDebug", { fg = palette.sky })
    hl("SnacksNotifierBorderError", { fg = palette.rose })
    hl("SnacksNotifierBorderInfo", { fg = palette.water })
    hl("SnacksNotifierBorderTrace", { fg = palette.blossom })
    hl("SnacksNotifierBorderWarn", { fg = palette.wood })

    -- Gitsigns
    hl("GitSignsAddPreview", { link = "DiffChange" })
    hl("GitSignsAddInline", { link = "DiffText" })
    hl("GitSignsChangeInline", { link = "DiffText" })
    hl("GitSignsDeleteInline", { link = "DiffText" })
    hl("GitSignsDeleteVirtLn", { fg = colors.blend(palette.bg, palette.rose, 60) })
    hl("GitSignsDeleteVirtLnInLine", { fg = palette.rose, bg = colors.blend(palette.bg, palette.rose, 20) })

    -- Oil git status
    hl("OilGitAdded", { fg = palette.leaf })
    hl("OilGitModified", { fg = palette.wood })
    hl("OilGitRenamed", { fg = palette.blossom })
    hl("OilGitDeleted", { fg = palette.rose })
    hl("OilGitCopied", { fg = palette.blossom })
    hl("OilGitConflict", { fg = palette.rose, bold = true })
    hl("OilGitUntracked", { fg = palette.water })
    hl("OilGitIgnored", { fg = colors.blend(palette.bg, palette.fg, 30) })

    -- Snacks explorer
    hl("SnacksPickerGitStatusUntracked", { fg = palette.wood })
  end

  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = { "zenbones", "zenwritten", "zenburned", "*bones" },
    group = vim.api.nvim_create_augroup("zenbones-overrides", { clear = true }),
    callback = function()
      vim.schedule(apply_overrides)
    end,
  })

  -- Apply immediately if already on a matching scheme
  vim.schedule(apply_overrides)
end
