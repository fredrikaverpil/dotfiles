local registry = require("registry")

vim.pack.add({
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
})

local function folder()
  local cwd = vim.fn.getcwd()
  return cwd:match("([^/]+)$")
end

local base_sections = {
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

local opts = {
  options = {
    theme = "auto",
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    globalstatus = true,
  },
  sections = base_sections,
  extensions = { "man", "quickfix" },
}

-- Initial setup (statusline visible from first frame)
require("lualine").setup(opts)

-- After all plugins loaded, re-setup with registry injections
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.tbl_isempty(registry.lualine) then
      return
    end
    for section, components in pairs(registry.lualine) do
      local base = base_sections[section]
      if base then
        -- Prepend injected components before the base ones
        local merged = {}
        vim.list_extend(merged, components)
        vim.list_extend(merged, base)
        opts.sections[section] = merged
      end
    end
    require("lualine").setup(opts)
  end,
})

vim.opt.showmode = false
