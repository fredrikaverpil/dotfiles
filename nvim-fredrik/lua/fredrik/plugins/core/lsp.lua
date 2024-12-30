--- @param server string The LSP name.
--- @param server_opts vim.lsp.Config The LSP config.
local function start_lsp(server, server_opts)
  local lsp = require("lspconfig")[server]

  -- local config_def = require("lspconfig.configs")[server].config_def
  -- local docs = config_def.docs
  -- local default_config = config_def.default_config

  if lsp.setup ~= nil then
    -- see all server configurations: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
    lsp.setup(server_opts)
    vim.cmd([[LspStart]])
  else
    vim.notify("LSP server setup fn not found: " .. server, vim.log.levels.ERROR)
  end
end

local lsp_startup_status = {}

local function wait_for_lsp_startup(server, timeout_ms, callback)
  timeout_ms = timeout_ms or 5000 -- 5 second default timeout
  local start_time = vim.uv.now()

  local function check_lsp()
    -- Check if LSP is already running
    local clients = vim.lsp.get_clients({ name = server })
    if #clients > 0 then
      callback(true)
      return
    end

    -- Check if we're still within timeout
    if (vim.uv.now() - start_time) > timeout_ms then
      callback(false)
      return
    end

    -- Schedule next check
    vim.defer_fn(check_lsp, 100)
  end

  check_lsp()
end

local function create_server_setup_autocmds(opts)
  -- Setup LSP for specific filetypes, using autocmd.
  for server, server_opts in pairs(opts.servers) do
    if server_opts then
      if server_opts.filetypes == nil then
        vim.notify("No filetypes specified for LSP server: " .. server, vim.log.levels.ERROR)
      else
        vim.api.nvim_create_autocmd("FileType", {
          pattern = server_opts.filetypes,
          callback = function(ev)
            -- Check if LSP is already running
            local clients = vim.lsp.get_clients({ name = server })
            if #clients > 0 then
              vim.notify(vim.inspect("Attaching LSP: " .. server .. " to existing client with id " .. clients[1].id))
              vim.lsp.buf_attach_client(ev.buf, clients[1].id)
              return
            end

            -- Check if LSP is already starting up
            if lsp_startup_status[server] then
              vim.notify("LSP " .. server .. " is already starting up, waiting... (" .. ev.file .. ")")
              wait_for_lsp_startup(server, 5000, function(success)
                if success then
                  clients = vim.lsp.get_clients({ name = server })
                  if #clients > 0 then
                    vim.notify(vim.inspect("Attaching LSP: " .. server .. " to existing client with id " .. clients[1].id .. " (" .. ev.file .. ")"))
                    vim.lsp.buf_attach_client(ev.buf, clients[1].id)
                  end
                end
              end)
              return
            end

            -- Start LSP
            lsp_startup_status[server] = true
            vim.notify(vim.inspect("Starting LSP: " .. server))
            start_lsp(server, server_opts)

            -- Clear startup status after a delay
            vim.defer_fn(function()
              lsp_startup_status[server] = nil
            end, 5000)
          end,
        })
      end
    end
  end
end

local function ensure_servers_installed(opts)
  -- Ensure LSP binaries are installed with mason-lspconfig.
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
    })
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
        opts_extend = {
          "sources.default",
        },
      },
      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      {
        "artemave/workspace-diagnostics.nvim",
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
      -- per language extension of LSP settings
      if opts.extends then
        for extendee, servers in pairs(opts.extends) do
          for server, server_opts in pairs(servers.servers) do
            -- vim.notify("Extending " .. server .. " on behalf of " .. extendee)
            opts.servers = require("fredrik.utils.table").deep_merge(opts.servers, { [server] = server_opts })
          end
        end
      end

      -- set up diagnostics
      require("fredrik.utils.diagnostics").setup_diagnostics()

      -- LSP servers and clients (like Neovim) are able to communicate to each other what
      -- features they support.
      -- By default, Neovim doesn't support everything that is in the LSP Specification.
      -- When you add nvim-cmp, blink, luasnip, etc. Neovim now has *more* capabilities.
      -- So, we create new capabilities here, and then broadcast that to the LSP servers.
      local client_capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), require("blink.cmp").get_lsp_capabilities())
      for server, server_opts in pairs(opts.servers) do
        local extended_capabilities = vim.tbl_deep_extend("force", client_capabilities, server_opts.capabilities or {})
        opts.servers[server].capabilities = extended_capabilities
      end

      -- FIXME: workaround for https://github.com/neovim/neovim/issues/28058
      for server, server_opts in pairs(opts.servers) do
        for _, v in pairs(server_opts) do
          if type(v) == "table" and v.workspace then
            v.workspace.didChangeWatchedFiles = {
              dynamicRegistration = false,
              relativePatternSupport = false,
            }
          end
        end
      end

      -- add custom on_attach
      for server, server_opts in pairs(opts.servers) do
        local on_attach = server_opts.on_attach

        server_opts.on_attach = function(client, bufnr)
          -- call original on_attach
          if on_attach ~= nil then
            on_attach(client, bufnr)
          end

          -- setup codelens
          if client.supports_method("textDocument/codeLens") then
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
              buffer = bufnr,
              callback = vim.lsp.codelens.refresh,
            })
          end

          -- setup folding
          if client.supports_method("textDocument/foldingRange") and require("fredrik.utils.version").is_neovim_0_11_0() then
            require("fredrik.config.options").treesitter_foldexpr()
          end

          -- FIXME: causes crash here
          -- set up workspace diagnostics
          -- require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
        end
      end

      ensure_servers_installed(opts)

      local native_lsp_enabled = true
      if require("fredrik.utils.version").is_neovim_0_11_0() and native_lsp_enabled then
        -- use native vim.lsp functionality
        -- https://github.com/neovim/neovim/pull/31031

        for server, server_opts in pairs(opts.servers) do
          local cmd = server_opts.cmd
          if cmd == nil then
            vim.notify("No cmd specified for LSP server: " .. server, vim.log.levels.ERROR)
            return
          end

          vim.lsp.config[server] = server_opts
          vim.lsp.enable(server, true)
        end
      else
        -- use lspconfig
        create_server_setup_autocmds(opts)
      end

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
}
