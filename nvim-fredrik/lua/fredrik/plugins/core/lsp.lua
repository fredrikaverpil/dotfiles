local version = require("fredrik.utils.version")

-- Extend LSP capabilities and set up LSP servers.
--
-- LSP servers and clients (like Neovim) are able to communicate to each other what
-- features they support.
-- By default, Neovim doesn't support everything that is in the LSP Specification.
-- When you add nvim-cmp, blink, luasnip, etc. Neovim now has *more* capabilities.
-- So, we create new capabilities here, and then broadcast that to the LSP servers.
--
---@param servers table<string, vim.lsp.Config>
local function extend_capabilities(servers)
  local client_capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("blink.cmp").get_lsp_capabilities()
  )
  for server, server_opts in pairs(servers) do
    local extended_capabilities = vim.tbl_deep_extend("force", client_capabilities, server_opts.capabilities or {})
    servers[server].capabilities = extended_capabilities
  end

  -- FIXME: workaround for https://github.com/neovim/neovim/issues/28058
  if servers["gopls"] ~= nil then
    local server_opts = servers["gopls"]
    for _, v in pairs(server_opts) do
      if type(v) == "table" and v.workspace then
        -- vim.notify(vim.inspect("Disabling workspace/didChangeWatchedFiles for " .. server), vim.log.levels.INFO)
        v.workspace.didChangeWatchedFiles = {
          dynamicRegistration = false,
          relativePatternSupport = false,
        }
      end
    end
  end
end

--- Ensure LSP binaries are installed with mason-lspconfig.
---@param servers table<string, vim.lsp.Config>
local function ensure_servers_installed(servers)
  local supported_servers = {}
  local have_mason_lspconfig, _ = pcall(require, "mason-lspconfig")
  if have_mason_lspconfig then
    local mappings = require("mason-lspconfig").get_mappings()
    supported_servers = vim.tbl_keys(mappings.lspconfig_to_package)
    local enabled_servers = {}
    for server, server_opts in pairs(servers) do
      if server_opts and not server_opts.enabled == false then
        if server_opts.mason ~= false and vim.tbl_contains(supported_servers, server) then
          table.insert(enabled_servers, server)
        elseif server_opts.mason == false then
          vim.notify("Skipping LSP server installation: " .. server, vim.log.levels.WARN)
        end
      end
    end
    -- See `:h mason-lspconfig
    require("mason-lspconfig").setup({
      automatic_enable = false,
      ensure_installed = enabled_servers,
    })
  end
end

--- Configure and enable LSP servers.
---@param servers table<string, vim.lsp.Config>
local function register_lsp_servers(servers)
  for server, server_opts in pairs(servers) do
    if server_opts.enabled == false then
      vim.lsp.enable(server, false)
    else
      -- vim.lsp.config[server] = server_opts -- just write options without extending
      vim.lsp.config(server, server_opts) -- extends from lsp.config
      vim.lsp.enable(server, true)

      if vim.lsp.config[server].cmd == nil then
        vim.notify("No cmd specified for LSP server: " .. server, vim.log.levels.ERROR)
      end
      if vim.lsp.config[server].filetypes == nil and not vim.tbl_contains({ "copilot" }, server) then
        vim.notify("No filetypes specified for LSP server: " .. server, vim.log.levels.ERROR)
      end
      if not vim.lsp.config[server].root_dir and not vim.lsp.config[server].root_markers then
        vim.notify("No root_dir or root_markers specified for LSP server: " .. server, vim.log.levels.ERROR)
      end
      if vim.lsp.config[server].root_dir and vim.lsp.config[server].root_markers then
        vim.notify(
          "Both root_dir and root_markers specified for LSP server (root_dir will be used): " .. server,
          vim.log.levels.ERROR
        )
      end
    end
  end
end

-- Register LSP attach autocmd.
local function register_lspattach_autocmd()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach-keymaps", { clear = true }),
    ---@param args vim.api.keyset.create_autocmd.callback_args
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        -- set up codelens
        if client:supports_method("textDocument/codeLens", args.buf) then
          vim.lsp.codelens.refresh()
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer = args.buf,
            callback = vim.lsp.codelens.refresh,
          })
        end

        -- set up workspace diagnostics
        if client:supports_method("workspace/diagnostic", args.buf) then
          -- WARNING: not sure if this is the intended use case. Let's see...
          vim.notify_once(vim.inspect("Setting up workspace diagnostics for " .. client.name), vim.log.levels.WARN)
          ---@type vim.lsp.WorkspaceDiagnosticsOpts
          local opts = { client_id = client.id }
          vim.lsp.buf.workspace_diagnostics(opts)
        end

        -- setup LSP-provided folding
        if client:supports_method("textDocument/foldingRange", args.buf) then
          require("fredrik.config.options").lsp_foldexpr()
        end

        -- setup inline completion (only neovim 0.12+)
        if version.is_neovim_0_12_0() and vim.lsp.inline_completion then
          if client:supports_method("textDocument/inlineCompletion", args.buf) then
            vim.lsp.inline_completion.enable(true)
          end
        end
      end

      -- set up keymaps
      require("fredrik.config.keymaps").setup_lsp_autocmd_keymaps(args.buf)
    end,
  })
end

return {
  {
    "virtual-lsp-config",
    virtual = true, -- NOTE: not an actual plugin
    event = "VeryLazy",
    dependencies = {
      {
        -- provides LSP server configurations to vim.lsp.config.
        "neovim/nvim-lspconfig",
        enabled = true, -- for debugging
      },
      {
        "b0o/SchemaStore.nvim",
        version = false, -- last release is very old
      },
      {
        "mason-org/mason-lspconfig.nvim",
        -- NOTE: this is here because mason-lspconfig must install servers prior to running nvim-lspconfig
        lazy = false,
        dependencies = {
          {
            -- NOTE: this is here because mason.setup must run prior to running nvim-lspconfig
            -- see mason.lua for more settings.
            "mason-org/mason.nvim",
            lazy = false,
          },
        },
      },
      {
        "saghen/blink.cmp",
        opts_extend = {
          "sources.default",
        },
      },
    },
    opts = {
      servers = {
        -- -- Example LSP settings below for opts.servers:
        -- lua_ls = {
        --   cmd = { ... },
        --   filetypes = { ... },
        --   root_dir = function() ... end,
        --   root_markers = { ... },
        --   on_attach = { ... },
        --   capabilities = { ... },
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
      extend_capabilities(opts.servers)
      ensure_servers_installed(opts.servers)
      register_lsp_servers(opts.servers)
      register_lspattach_autocmd()

      require("fredrik.config.keymaps").setup_lsp_keymaps()
    end,
  },
}
