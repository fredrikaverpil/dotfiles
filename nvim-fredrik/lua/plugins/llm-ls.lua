return {
  {

    "huggingface/llm.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "llm-ls" })
        end,
      },
    },
    opts = {
      backend = "ollama",
      model = "codellama:7b",
      accept_keymap = "<Tab>",
      dismiss_keymap = "<S-Tab>",
      url = "http://localhost:11434/api/generate",
      request_body = {
        options = {
          temperature = 0.2,
          top_p = 0.95,
        },
      },
      fim = {
        enabled = true,
        prefix = "<fim_prefix>",
        middle = "<fim_middle>",
        suffix = "<fim_suffix>",
      },
      context_window = 400,
      enable_suggestions_on_startup = true,
    },
  },
}
