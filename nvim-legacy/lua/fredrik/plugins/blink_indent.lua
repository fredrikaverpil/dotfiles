return {
  {
    "saghen/blink.indent",
    --- @module 'blink.indent'
    --- @type blink.indent.Config
    opts = {
      blocked = {
        filetypes = { include_defaults = true, "snacks_picker_preview" },
      },
      static = {
        enabled = false,
      },
      scope = {
        highlights = { "BlinkIndentScope" }, -- avoid multiple colors
      },
    },
  },
}
