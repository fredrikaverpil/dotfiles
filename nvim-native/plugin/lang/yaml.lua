-- Custom filetypes for GitHub Actions and Dependabot
vim.filetype.add({
	pattern = {
		[".*/%.github/dependabot.yml"] = "dependabot",
		[".*/%.github/dependabot.yaml"] = "dependabot",
		[".*/%.github/workflows[%w/]+.*%.yml"] = "gha",
		[".*/%.github/workflows/[%w/]+.*%.yaml"] = "gha",
	},
})

-- Use the yaml treesitter parser for custom filetypes
vim.treesitter.language.register("yaml", "gha")
vim.treesitter.language.register("yaml", "dependabot")

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "yaml", "gha", "dependabot" },
	callback = function(event)
		vim.opt_local.tabstop = 2
		vim.opt_local.softtabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true

		-- Load yaml indent for custom filetypes that alias yaml
		if event.match ~= "yaml" then
			vim.cmd.runtime("indent/yaml.vim")
		end
	end,
})
