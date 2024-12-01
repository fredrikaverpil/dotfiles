-- set up backwards compatibility
require("fredrik.utils.version").setup_backwards_compat()

-- set options
require("fredrik.config.options")

-- set auto commands
require("fredrik.config.autocmds")

-- setup up package manager, load plugins and configs
require("fredrik.config.lazy")
