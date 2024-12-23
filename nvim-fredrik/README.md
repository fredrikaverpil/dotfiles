# nvim-fredrik

![neovim](https://github.com/user-attachments/assets/92cf0049-05fc-4ca8-8ec2-d1ff58e48ab9)

## My custom Neovim setup

```bash
# if you want to try it out locally
git clone git@github.com:fredrikaverpil/dotfiles ~/.config/fredrikaverpil/dotfiles
NVIM_APPNAME=fredrikaverpil/dotfiles/nvim-fredrik nvim
```

### Main initialization

In [lua/fredrik/init.lua](lua/fredrik/init.lua), the entire config is loaded in
sequence. First general options and general autocommands are set up. Then, the
lazy.nvim package manager is invoked.

- [lua/fredrik/config/options.lua](lua/fredrik/config/options.lua)
- [lua/fredrik/config/autocmds.lua](lua/fredrik/config/autocmds.lua)
- [lua/fredrik/config/lazy.lua](lua/fredrik/config/lazy.lua)

The lazy.nvim package manager is instructed to read plugins (see the `spec`
config of the `lazy.lua`) in this order:

1. Any plugin's config from the `plugins` folder.
2. Plugin configs for a specific language from the `plugins/lang` folder.
3. Plugin configs for "core" from the `plugins/core` folder.

### Core plugin configs

A "core" plugin config is just a term I coined, and represents a plugin which
defines a `config` and takes in multiple merged `opts` defined in several other
lua files.

This gives the ability to specify LSP configs in multiple files, which are then
assembled and loaded in the "core" LSP plugin config.

### Per-project overrides ("local spec")

Lazy.nvim comes with the capability of reading a local, per-project, `.lazy.lua`
file, which serves as a way to make changes and overrides, based on project
needs. The contents of the `.lazy.lua` will be loaded at the end of the
lazy.nvim spec and requires the lazy.nvim option `local_spec = true`.

> [!NOTE]
>
> [Here's a GitHub search](https://github.com/search?q=.lazy.lua+language%3ALua&type=code&l=Lua)
> for`.lazy.lua`.

Concrete example below, where conform.nvim is overidden to pass certain
arguments to the `gci` formatter:

```lua
-- .lazy.lua

return {

  {
    "stevearc/conform.nvim",
    -- https://github.com/stevearc/conform.nvim
    enabled = true,
    opts = function(_, opts)
      local formatters = require("conform.formatters")

      vim.api.nvim_echo({ { "Using custom import ordering", "None" } }, false, {})
      -- https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/gci.lua
      formatters.gci.args = {
        "write",
        "-s",
        "standard",
        "-s",
        "default",
        "-s",
        "Prefix(github.com/shipwallet)",
        "--skip-generated",
        "--skip-vendor",
        "$FILENAME",
      }
    end,
  },
}
```
