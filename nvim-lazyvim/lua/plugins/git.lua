return {

	-- git signs
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},

	-- diffview
	-- {
	--   "sindrets/diffview.nvim",
	--   dependencies = {
	--     { "nvim-lua/plenary.nvim" },
	--   },
	--   config = function()
	--     require("diffview").setup({
	--     enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
	--     })
	--   end,
	-- },

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
