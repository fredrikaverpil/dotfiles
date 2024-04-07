-- set up backwards compatibility
require("utils.version").setup_backwards_compat()

-- set options
require("config.options")

-- set auto commands
require("config.autocmds")

-- setup up package manager, load plugins and configs
require("config.lazy")
