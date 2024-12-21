G_workspace_diagnostics_enabled = true
G_client_capabilities = {}
G_lspconfig_opts = {}

--- LSP server setup (for each LSP). Intended to be compatible with mason-lspconfig.
--- @param server string
local function setup_handler(server)
  -- print("Setting up LSP: " .. server)

  --- Defaults for the given LSP server.
  ---
  --- Example:
  -- local defaults = {
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
  --   }
  -- }
  local defaults = {}
  defaults.capabilities = vim.deepcopy(G_client_capabilities)
  defaults.on_attach = function(client, bufnr)
    -- Return early if the buffer does not exist
    if client.supports_method("textDocument/codeLens") then
      vim.lsp.codelens.refresh()
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        buffer = bufnr,
        callback = vim.lsp.codelens.refresh,
      })
    end
    if client.supports_method("textDocument/foldingRange") and require("fredrik.utils.version").is_neovim_0_11_0() then
      vim.api.nvim_set_option_value("foldmethod", "expr", { scope = "local" })
      vim.api.nvim_set_option_value("foldexpr", "v:lua.vim.lsp.foldexpr()", { scope = "local" })
      -- vim.api.nvim_set_option_value("foldtext", "v:lua.vim.lsp.foldtext()", { scope = "local" }) -- NOTE: using custom foldtext in options.lua
    end
    if G_workspace_diagnostics_enabled then
      require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
    end
  end

  -- merge defaults with user settings for this LSP server
  local server_opts = vim.tbl_deep_extend("force", defaults, G_lspconfig_opts.servers[server] or {})

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
    -- see all server configurations: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
    lsp.setup(server_opts)
  else
    vim.notify("LSP server setup fn not found: " .. server, vim.log.levels.ERROR)
  end
end

local function ensure_servers_installed(opts)
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
      ensure_installed = enabled_servers,
      -- handlers = { setup_handler }, -- NOTE: enabling this loads all LSPs on Neovim startup.
    })
  end
end

local function create_server_setup_autocmds(opts)
  -- Setup LSP for specific filetypes, using autocmd.
  for server, server_opts in pairs(opts.servers) do
    if server_opts then
      if server_opts.filetypes == nil then
        vim.notify("No filetypes specified for LSP server: " .. server, vim.log.levels.WARN)
      else
        vim.api.nvim_create_autocmd("FileType", {
          pattern = server_opts.filetypes,
          callback = function(ev)
            -- print("In autocmd, for language " .. ev.match .. ", using server " .. server)
            local clients = vim.lsp.get_clients({ name = server })
            if #clients == 0 then
              setup_handler(server)
              vim.cmd([[LspStart]])
            end
          end,
        })
      end
    end
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    lazy = true,
    -- Remove the event configuration
    -- event = { "BufReadPost", "BufWinEnter" },
    event = "VeryLazy",
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
      extends = {
        -- LSP settings extensions (not overrides).
        -- Example where gotmpl extends gopls and html:
        -- gotmpl = {
        --   servers = {
        --     gopls = { ... },
        --     html = { ... },
        --   },
        -- }
      },
      servers = {
        -- -- Example LSP settings below for opts.servers:
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
      --keys of opts.servers
      -- TODO: extend config with inspiration from
      -- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/lsp/init.lua

      -- per language extension of LSP settings
      if opts.extends then
        for extendee, servers in pairs(opts.extends) do
          for server, server_opts in pairs(servers.servers) do
            -- vim.notify("Extending " .. server .. " on behalf of " .. extendee)
            opts.servers = require("fredrik.utils.table").deep_merge(opts.servers, { [server] = server_opts })
          end
        end
      end

      require("fredrik.utils.diagnostics").setup_diagnostics()

      -- LSP servers and clients (like Neovim) are able to communicate to each other what
      -- features they support.
      -- By default, Neovim doesn't support everything that is in the LSP Specification.
      -- When you add nvim-cmp, blink, luasnip, etc. Neovim now has *more* capabilities.
      -- So, we create new capabilities here, and then broadcast that to the LSP servers.
      local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      local has_blink, blink = pcall(require, "blink.cmp")
      local client_capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        -- has_cmp and cmp_nvim_lsp.default_capabilities() or {},
        has_blink and blink.get_lsp_capabilities() or {}
      )

      -- set global variables which must be accessible from the `setup_handler` function.
      G_client_capabilities = client_capabilities
      G_lspconfig_opts = opts

      ensure_servers_installed(opts)
      create_server_setup_autocmds(opts) -- set up LSP based on filetype

      -- set up keymaps
      require("fredrik.config.keymaps").setup_lsp_keymaps()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach-keymaps", { clear = true }),
        callback = function(event)
          require("fredrik.config.keymaps").setup_lsp_autocmd_keymaps(event)
        end,
      })
    end,
  },

  {
    "mhanberg/output-panel.nvim",
    enabled = false, -- causes errors quite often
    event = "VeryLazy",
    config = function()
      require("output_panel").setup()
    end,
    cmd = { "OutputPanel" },
  },
}
