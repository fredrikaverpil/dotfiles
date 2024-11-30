G_workspace_diagnostics_enabled = true
G_capabilities = {}
G_opts = {}

--- LSP server setup (for each LSP). Intended to be used with mason-lspconfig.
---
--- Example settings for opts.servers[server]:
---
---   cmd = { ... },
---   filetypes = { ... },
---   capabilities = { ... },
---   on_attach = { ... },
---   settings = {
---     Lua = {
---       workspace = {
---         checkThirdParty = false,
---       },
---       codeLens = {
---         enable = true,
---       },
---       completion = {
---         callSnippet = "Replace",
---       },
---     },
---   }
--- @param server table
local function setup_handler(server)
  local defaults = {}
  defaults.capabilities = vim.deepcopy(G_capabilities)
  local server_capabilities = require("blink.cmp").get_lsp_capabilities(server.capabilities)
  defaults.capabilities = vim.tbl_deep_extend("force", defaults.capabilities, server_capabilities)
  defaults.on_attach = function(client, bufnr)
    if client.supports_method("textDocument/codeLens") then
      vim.lsp.codelens.refresh()
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        buffer = bufnr,
        callback = vim.lsp.codelens.refresh,
      })
    end
    if client.supports_method("textDocument/foldingRange") and require("utils.version").is_neovim_0_11_0() then
      vim.notify("Using LSP for folds: " .. server, vim.log.levels.INFO)
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "v:lua.vim.lsp.foldexpr()"
    end
    if G_workspace_diagnostics_enabled then
      require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
    end
  end

  -- merge defaults with user settings for this LSP server
  local server_opts = require("utils.table").deep_merge(defaults, G_opts.servers[server] or {})

  -- FIXME: workaround for https://github.com/neovim/neovim/issues/28058
  for _, v in pairs(server_opts) do
    if type(v) == "table" and v.workspace then
      v.workspace.didChangeWatchedFiles = {
        dynamicRegistration = false,
        relativePatternSupport = false,
      }
    end
  end

  local lsp = require("lspconfig")[server]
  if lsp.setup ~= nil then
    lsp.setup(server_opts)
  else
    vim.notify("LSP server setup fn not found: " .. server, vim.log.levels.ERROR)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    lazy = true,
    event = { "BufReadPost", "BufWinEnter" },
    dependencies = {
      {
        "b0o/SchemaStore.nvim",
        version = false, -- last release is very old
      },
      {
        "williamboman/mason-lspconfig.nvim",
        -- NOTE: this is here because mason-lspconfig must install servers prior to running nvim-lspconfig
        lazy = false,
        dependencies = {
          {
            -- NOTE: this is here because mason.setup must run prior to running nvim-lspconfig
            -- see mason.lua for more settings.
            "williamboman/mason.nvim",
            lazy = false,
          },
        },
      },
      -- {
      --   "hrsh7th/nvim-cmp",
      --   enabled = true,
      --   -- NOTE: this is here because we get the default client capabilities from cmp_nvim_lsp
      --   -- see cmp.lua for more settings.
      -- },
      {
        "saghen/blink.cmp",
      },
      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      {
        "j-hui/fidget.nvim",
        enabled = false, -- TODO: figure out how this status shows without fidget
        opts = {},
      },
      {
        "artemave/workspace-diagnostics.nvim",
        enabled = G_workspace_diagnostics_enabled,
      },
    },
    opts = {
      servers = {
        -- -- Example LSP settings below:
        -- lua_ls = {
        --   cmd = { ... },
        --   filetypes = { ... },
        --   capabilities = { ... },
        --   on_attach = { ... },
        --   settings = {
        --     Lua = {
        --       workspace = {
        --         checkThirdParty = false,
        --       },
        --       codeLens = {
        --         enable = true,
        --       },
        --       completion = {
        --         callSnippet = "Replace",
        --       },
        --     },
        --   },
        -- },
      },
    },
    config = function(_, opts)
      -- TODO: extend config with inspiration from
      -- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/lsp/init.lua

      require("utils.diagnostics").setup_diagnostics()

      -- TODO: explain capabilities, see
      -- https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua#L526
      --
      -- LSP servers and clients are able to communicate to each other what features they support.
      -- By default, Neovim doesn't support everything that is in the LSP Specification.
      -- When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      -- So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local client_capabilities = vim.lsp.protocol.make_client_capabilities()

      -- NOTE: if using nvim-cmp...
      -- local completion_capabilities = require("cmp_nvim_lsp").default_capabilities()
      -- local client_capabilities = vim.tbl_deep_extend("force", client_capabilities, completion_capabilities)

      -- set global variables which must be accessible from the `setup_handler` function.
      G_capabilities = client_capabilities
      G_opts = opts

      -- Ensure LSP servers are installed with mason-lspconfig.
      local supported_servers = {}
      local have_mason_lspconfig, _ = pcall(require, "mason-lspconfig")
      if have_mason_lspconfig then
        supported_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
        local enabled_servers = {}
        for server, server_opts in pairs(opts.servers) do
          if server_opts then
            if server_opts.mason ~= false and vim.tbl_contains(supported_servers, server) then
              table.insert(enabled_servers, server)
            else
              vim.notify("LSP server not supported by mason-lspconfig: " .. server, vim.log.levels.WARN)
            end
          end
        end

        -- See `:h mason-lspconfig
        require("mason-lspconfig").setup({
          ---@type string[]
          ensure_installed = enabled_servers, -- NOTE: more like "ensure running"
          ---@type table<string, fun(server_name: string)>?
          handlers = { setup_handler },
        })

        --  NOTE: this is not something I'm using right now, but it's here for reference.
        -- -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
        -- for server, server_opts in pairs(opts.servers) do
        --   if server_opts.mason == false or not vim.tbl_contains(supported_servers, server) then
        --     -- e.g. if opts.servers.lua_ls.mason = false or if lua_ls is not supported by mason-lspconfig.
        --     vim.notify("Manual LSP setup for: " .. server, vim.log.levels.WARN)
        --     setup_handler(server)
        --   end
        -- end
      end

      require("config.keymaps").setup_lsp_keymaps()

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach-keymaps", { clear = true }),
        callback = function(event)
          require("config.keymaps").setup_lsp_autocmd_keymaps(event)
        end,
      })
    end,
  },
}
