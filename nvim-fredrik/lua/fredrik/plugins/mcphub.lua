return {

  -- MCP server info:
  -- https://github.com/modelcontextprotocol/servers
  -- https://www.aimcp.info/en

  {
    "ravitemer/mcphub.nvim",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
      {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = function(_, opts)
          opts.mcphub = {
            lualine_component = {
              require("mcphub.extensions.lualine"),
            },
          }
        end,
      },
    },
    build = "npm install -g mcp-hub@latest", -- Installs required mcp-hub npm module
    config = function()
      require("mcphub").setup({
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
