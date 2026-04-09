vim.pack.add({
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
})

require("defer").on_vim_enter(function()
  local registry = require("registry")

  local function folder()
    local cwd = vim.fn.getcwd()
    return cwd:match("([^/]+)$")
  end

  local sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diagnostics" },
    lualine_c = {
      { folder, color = { gui = "bold" }, separator = "/", padding = { left = 1, right = 0 } },
      { "filename", path = 1, padding = { left = 0, right = 1 } },
    },
    lualine_x = { "encoding", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  }

  -- Prepend registry components into each section
  for section, components in pairs(registry.lualine) do
    if sections[section] then
      local merged = {}
      vim.list_extend(merged, components)
      vim.list_extend(merged, sections[section])
      sections[section] = merged
    end
  end

  local extensions = { "man", "quickfix" }
  vim.list_extend(extensions, registry.lualine.extensions or {})

  require("lualine").setup({
    options = {
      theme = "auto",
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      globalstatus = true,
    },
    sections = sections,
    extensions = extensions,
  })

  vim.opt.showmode = false
end)
