vim.pack.add({
  { src = "https://github.com/lawrence-laz/neotest-zig", version = vim.version.range("1.*") },
})

require("registry").add({
  lsp_servers = { "zls" },
  mason_tools = { "zls" },
  code_runner = { zig = { "zig run" } },
  neotest = {
    adapters = {
      {
        module = "neotest-zig",
        opts = {
          dap = { adapter = "lldb" },
        },
      },
    },
  },
})
