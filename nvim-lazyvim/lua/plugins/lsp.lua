-- https://www.lazyvim.org/plugins/lsp

return {

	-- chage mason config
	{
		"williamboman/mason.nvim",
		-- opts will be merged with the parent spec
		opts = {
			ensure_installed = {
				-- python
				-- "debugpy",
				-- "mypy",

				-- lua
				"lua-language-server",
				"stylua",

				-- shell
				"shellcheck",
				"shfmt",

				-- docker
				"dockerfile-language-server",

				-- javascript/typescript
				"prettier",
				"typescript-language-server",
				"eslint-lsp",
			},
		},
	},

	-- change null-ls config
	{
		"jose-elias-alvarez/null-ls.nvim",
		dependencies = { "mason.nvim" },
		event = { "BufReadPre", "BufNewFile" },
		opts = function()
			local mason_registry = require("mason-registry")
			local null_ls = require("null-ls")
			local formatting = null_ls.builtins.formatting
			local diagnostics = null_ls.builtins.diagnostics

			null_ls.setup({
				-- debug = true, -- Turn on debug for :NullLsLog
				debug = true,
				-- diagnostics_format = "#{m} #{s}[#{c}]",
				sources = {
					-- list of supported sources:
					-- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

					-- get from $PATH
					diagnostics.ruff,
					diagnostics.mypy,
					formatting.black,

					-- get from mason
					diagnostics.shellcheck.with({
						command = mason_registry.get_package("shellcheck").path,
					}),
					formatting.stylua.with({
						command = mason_registry.get_package("stylua").path,
					}),
					formatting.shfmt.with({
						command = mason_registry.get_package("shfmt").path,
					}),
					formatting.prettier.with({
						command = mason_registry.get_package("prettier").path,
					}),
				},
			})
		end,
	},
}
