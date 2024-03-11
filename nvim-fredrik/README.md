# nvim-fredrik

My custom Neovim config.

## Ideas

- Define hierarchical plugin dependencies, so to make it clear what depends on what.
- Base configuration which calls plugins and sets them up.
  - Per-language lua configs, which is passed on to the base configuration.
    - Per-project lua config overrides, which is passed on to the per-language configs.

## To do

- [x] Proof of concept on base config + per-language configs.
- [x] Per-project configs.
- Review LSP settings...
- Options...
- Keymaps...
- Add missing plugins...
