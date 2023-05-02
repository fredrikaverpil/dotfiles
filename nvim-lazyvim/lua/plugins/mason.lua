return {

	-- NOTE: also see ':h Lazy' or run :Lazy to lazy-load all plugins

	-- add any tools you want to have installed below
	{
		"williamboman/mason.nvim",
		-- opts will be merged with the parent spec
		opts = {
			ensure_installed = {
				-- python
				"debugpy",
				-- lua
				"stylua",
				-- shell
				"shellcheck",
				"shfmt",
				-- javascript/typescript
				"prettier",
			},
		},
	},
}
