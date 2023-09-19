-- also see https://www.lazyvim.org/extras/lang/go
return {

	{
		"olexsmir/gopher.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-treesitter/nvim-treesitter" },
			config = function()
				require("gopher").setup()
			end,
		},
	},
}
