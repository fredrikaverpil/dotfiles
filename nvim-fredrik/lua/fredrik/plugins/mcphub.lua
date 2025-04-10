return {

  -- MCP server info:
  -- https://github.com/modelcontextprotocol/servers
  -- https://www.aimcp.info/en

  {
    "ravitemer/mcphub.nvim",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
    },
    -- cmd = "MCPHub", -- lazily start the hub when `MCPHub` is called
    build = "npm install -g mcp-hub@latest", -- Installs required mcp-hub npm module
    config = function()
      require("mcphub").setup({
        -- Required options
        port = 3000, -- Port for MCP Hub server
        config = require("fredrik.utils.environ").getenv("DOTFILES") .. "/mcpservers.json",

        -- Optional options
        on_ready = function(hub)
          -- Called when hub is ready
          -- vim.notify(vim.inspect("MCP Hub is ready!"), vim.log.levels.INFO, { title = "MCP Hub" })
        end,
        on_error = function(err)
          -- Called on errors
          -- vim.notify(vim.inspect(err), vim.log.levels.ERROR, { title = "MCP Hub" })
        end,
        log = {
          level = vim.log.levels.WARN,
          to_file = false,
          file_path = nil,
          prefix = "MCPHub",
        },
      })
    end,
    cmd = { "MCPHub" },
  },
}
