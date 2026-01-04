vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    gohtml = "gotmpl",
  },
  -- filename = {},
  pattern = {
    [".*%.go%.tmpl"] = "gotmpl",
  },
})

local filetypes = { "gotmpl", "gohtml" }
local extensions = { "gotmpl", "gohtml", "tmpl" }

vim.api.nvim_create_autocmd("FileType", {
  pattern = filetypes,
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = false
  end,
})

return {
  {
    "virtual-lsp-config",
    dependencies = {
      {
        "mason-org/mason-lspconfig.nvim",
        dependencies = { "mason-org/mason.nvim" },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, {
            "gopls",
            -- "html",
          })
        end,
      },
    },
    opts = {
      servers = {
        -- TODO: evaluate https://github.com/yayolande/go-template-lsp

        ---@type vim.lsp.Config
        gopls = {
          filetypes = filetypes,
          settings = {
            gopls = {
              templateExtensions = extensions,
            },
          },
        },

        ---@type vim.lsp.Config
        -- superhtml = { filetypes = filetypes, settings = { superhtml = {} } },
      },
    },
    opts_extend = {
      "servers.gopls.filetypes",
      "servers.gopls.settings.gopls.templateExtensions",
      "servers.superhtml.filetypes",
    },
  },
}
