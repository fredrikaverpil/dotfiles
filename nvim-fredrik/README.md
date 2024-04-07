# nvim-fredrik

My custom Neovim config.

## Overall setup

- Main initialization in `init.lua`.
  - Load base configuration including base auto-commands.
  - Invoke lazy.nvim plugin manager.
    - Load plugins.
    - Load language specific "overrides".
    - Load project-specific "overrides" (lazyrc).
