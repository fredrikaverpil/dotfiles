# nvim-fredrik

![neovim](https://github.com/user-attachments/assets/92cf0049-05fc-4ca8-8ec2-d1ff58e48ab9)

## Features

- Taking a lot of inspiration from
  [LazyVim](https://github.com/LazyVim/LazyVim), but with the tranquility of
  maintaining it myself.
- Per-language configs.
- Per-project overrides.
- Notion of public vs private projects.
- Fzf-lua for certain files, grepping etc.
- Blink.cmp for completion.
- Native snippets.
- One unified keymap file.
- Conform.nvim for formatting.
- Nvim-lint for linting.
- Neotest and nvim-dap for testing and debugging.
- Snacks.nvim for QoL improvements.
- Mason for managing tools used by plugins and LSPs.
- Noice.nvim for cmdline improvement.
- Trouble.nvim for keeping track of diagnostics issues.
- Gx.nvim for universal `gx` keymap.
- Neo-tree for navigating files and folders.
- Native vim folding, using LSP when applicable.
- Diffview for reviewing PRs.
- GitHub Copilot enabled in public projects, disabled in private projects.
- AI chat via Codecompanion.
- And much, much more...

## Try it out! 🚀

```bash
# clone it down into your ~/.config folder
git clone https://github.com/fredrikaverpil/dotfiles.git ~/.config/fredrikaverpil/dotfiles

# run nvim with NVIM_APPNAME
NVIM_APPNAME=fredrikaverpil/dotfiles/nvim-fredrik nvim
```

> [!WARNING]
>
> I'm not maintaining my Neovim config for anyone besides myself. But I'm making
> it publicly available for others to draw inspiration from! 😊
>
> It's very likely that my config is tailored for my local setup, and that you
> will experience some minor issues. For example, I assume the `DOTFILES`
> environment variable exists, as this is something I know to always have on my
> systems. I also assume certain commandline tools to be available, like `fd`,
> `rg`, `fzf` etc.

## Design choices

I wanted to take a modular approach to my Neovim setup. This was made possible
thanks to the quite amazing [lazy.nvim](https://github.com/folke/lazy.nvim)
plugin manager.

### Main initialization

- In [lua/fredrik/init.lua](lua/fredrik/init.lua), the entire config is loaded
  in sequence.

  - First general options and general autocommands are set up. Finally, the
    lazy.nvim plugin manager is invoked for loading of all plugins.

- When loading all plugins, the `spec` (order of loading plugins) is defined in
  [lua/fredrik/config/lazy.lua](lua/fredrik/config/lazy.lua):

  1. Any plugin's config from the `plugins` folder.
  2. Plugin configs for a specific language from the `plugins/lang` folder.
  3. Plugin configs for "core" from the `plugins/core` folder.
  4. (Plugin configs from local `.lazy.lua`).

Below, I'll go through the characteristics of these levels of loading plugin
configs.

### Generic plugin configs

Plugin configs that are not associated with a certain language or needs complex
setup are considered just to be a "plain" plugin. Their configs are defined in
the [lua/fredrik/plugins](lua/fredrik/plugins) folder root.

### Per-language plugin configs

For a complete and nice experience when working in a certain language,
per-language configs are placed in
[lua/fredrik/plugins/lang](lua/fredrik/plugins/lang).

Formatting, linting and LSP configs are specified in the per-language plugin
configs. This provides a complete picture of what is supported by browsing a
language config file.

### Core plugin configs

A "core" plugin config is just a term I came up with for representing a plugin
which defines the `config` as part of its spec, and takes in multiple merged
`opts` defined in several other lua files (such as the per-language configs).
These "core" plugin configs reside in
[lua/fredrik/plugins/core](lua/fredrik/plugins/core).

This enables the ability to specify e.g. LSP configs in multiple files, which
are then assembled and loaded in the "core" LSP plugin config.

The end goal is to modularize the entire setup, using these "core" plugin
configs.

### Per-project overrides ("local spec") via local `.lazy.lua`

Lazy.nvim comes with the capability of reading a local, per-project, `.lazy.lua`
file, which serves as a way to make changes and overrides, based on project
needs. The contents of the `.lazy.lua` will be loaded at the end of the
lazy.nvim spec and requires the lazy.nvim option `local_spec = true`.

> [!NOTE]
>
> [Here's a GitHub search](https://github.com/search?q=.lazy.lua+language%3ALua&type=code&l=Lua)
> for`.lazy.lua`.
