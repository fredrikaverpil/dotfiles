require("lazyload").on_vim_enter(
  function()
    vim.pack.add({
      { src = "https://github.com/nvim-lualine/lualine.nvim" },
    })

    local function folder()
      local cwd = vim.fn.getcwd()
      return cwd:match("([^/]+)$")
    end

    require("lualine").setup({
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
        lualine_x = {
          {
            function()
              return require("dap").status()
            end,
            cond = function()
              return package.loaded["dap"] and require("dap").status() ~= ""
            end,
            icon = "",
          },
          "encoding",
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      extensions = { "man", "mason", "quickfix" },
    })

    vim.opt.showmode = false
  end,
  -- TODO: remove sync behavior, hide lualine until after leaving dashboard
  { sync = true }
)
