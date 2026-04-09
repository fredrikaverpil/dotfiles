vim.pack.add({
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
})

require("defer").on_vim_enter(function()
  local merge = require("merge")
  local registry = require("registry")

  local function folder()
    local cwd = vim.fn.getcwd()
    return cwd:match("([^/]+)$")
  end

  local opts = {
    options = {
      theme = "auto",
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      globalstatus = true,
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diagnostics" },
      lualine_c = {
        { folder, color = { gui = "bold" }, separator = "/", padding = { left = 1, right = 0 } },
        { "filename", path = 1, padding = { left = 0, right = 1 } },
      },
      lualine_x = { "encoding", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    extensions = { "man", "quickfix" },
  }

  merge(opts, registry.lualine.opts or {})

  -- Inject named section contributions (lualine decides placement)
  local sections = registry.lualine.sections or {}
  if sections.dap then
    table.insert(opts.sections.lualine_x, 1, sections.dap)
  end

  require("lualine").setup(opts)

  vim.opt.showmode = false
end)
