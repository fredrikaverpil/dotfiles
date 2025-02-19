# nvim-fredrik

![neovim](https://github.com/user-attachments/assets/92cf0049-05fc-4ca8-8ec2-d1ff58e48ab9)

## Features

- Taking a lot of inspiration from
  [LazyVim](https://github.com/LazyVim/LazyVim), but with the tranquility of
  maintaining it myself.
- Per-language configs.
- Per-project overrides.
- Notion of public vs private projects; GitHub Copilot enabled in public
  projects, disabled in private projects.
- Native LSP definitions (`vim.lsp.config` and `vim.lsp.enable`).
- Native snippets.
- Native vim folding, using LSP when applicable.
- Snacks, telescope, fzf-lua pickers for certain files, grepping etc.
- Inline image link rendering (kitty graphics protocol).
- Blink.cmp for completion.
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
- Diffview for reviewing PRs.
- AI chat via Codecompanion.
- And much, much more...

## Try it out! 🚀

> [!WARNING]
>
> Requires Neovim >= v0.11.0.

```sh
# clone repo
git clone https://github.com/fredrikaverpil/dotfiles.git

# create symlink
ln -s dotfiles/nvim-fredrik ~/.config/fredrik

# run nvim with NVIM_APPNAME=fredrik
NVIM_APPNAME=fredrik nvim
```

> [!NOTE]
>
> I'm not maintaining my Neovim config for anyone besides myself. But I'm making
> it publicly available for others to draw inspiration from! 😊

## Design choices

I wanted to take a modular approach to my Neovim setup. This was made possible
thanks to the quite amazing [lazy.nvim](https://github.com/folke/lazy.nvim)
plugin manager.

### Main initialization

- In [lua/fredrik/init.lua](lua/fredrik/init.lua), the entire config is loaded
  in sequence.
- When loading all plugins, the `spec` (order of loading plugins) is defined in
  [lua/fredrik/config/lazy.lua](lua/fredrik/config/lazy.lua):

  1. Any plugin's config from the `plugins` folder.
  2. Plugin configs for a specific language from the `plugins/lang` folder.
  3. Plugin configs for "core" from the `plugins/core` folder.
  4. (Per-project plugin configs from local per-project `.lazy.lua` file).

### Order of plugins loading

You can inspect the order of loading here:
[lua/fredrik/config/lazy.lua](lua/fredrik/config/lazy.lua).

#### Generic plugin configs

Plugin configs that are not associated with a certain language or needs complex
setup are considered just to be a "plain" plugin. Their configs are defined in
the [lua/fredrik/plugins](lua/fredrik/plugins) folder root.

#### Per-language plugin configs

For a complete and nice experience when working in a certain language,
per-language configs are placed in
[lua/fredrik/plugins/lang](lua/fredrik/plugins/lang).

Formatting, linting and LSP configs are specified in the per-language plugin
configs. This provides a complete picture of what is supported by browsing a
language config file. Removing a language lua file should remove everything that
is related to that language.

#### Core plugin configs

A "core" plugin config is just a term I came up with for representing a plugin
which defines the `config` as part of its spec, and takes in multiple merged
`opts` defined in several other lua files (such as the per-language configs).
These "core" plugin configs reside in
[lua/fredrik/plugins/core](lua/fredrik/plugins/core).

This enables the ability to specify e.g. LSP configs in multiple files, which
are then assembled and loaded in the "core" LSP plugin config.

The end goal is to modularize the entire setup, using these "core" plugin
configs.

#### Per-project overrides ("local spec") via local `.lazy.lua`

Lazy.nvim comes with the capability of reading a local, per-project, `.lazy.lua`
file, which serves as a way to make changes and overrides, based on project
needs. The contents of the `.lazy.lua` will be loaded at the end of the
lazy.nvim spec and requires the lazy.nvim option `local_spec = true`.

> [!NOTE]
>
> [Here's a GitHub search](https://github.com/search?q=path%3A%22.lazy.lua%22+language%3ALua+&type=code)
> for`.lazy.lua`.
