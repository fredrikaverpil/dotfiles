return {

	-- diffview
	{
		"sindrets/diffview.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
		},
		config = function()
			vim.opt.fillchars = "diff:╱"

			require("diffview").setup({
				enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
			})
		end,
		keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
				"<leader>gdc",
				function()
					vim.cmd("DiffviewOpen close")
				end,
				desc = "DiffviewClose (:tabclose)",
			},
			{
				"<leader>gdh",
				function()
					vim.cmd("DiffviewFileHistory")
				end,
				desc = "DiffviewFileHistory",
			},
			{
				"<leader>gdm",
				function()
					vim.cmd("DiffviewOpen main")
				end,
				desc = "DiffviewOpen main",
			},
			{
				"<leader>gdn",
				function()
					vim.cmd("DiffviewOpen master")
				end,
				desc = "DiffviewOpen master",
			},
		},
	},

	-- octo
	{
		"pwntester/octo.nvim",
		requires = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"kyazdani42/nvim-web-devicons",
		},
		config = function()
			require("octo").setup()
		end,
	},
}
