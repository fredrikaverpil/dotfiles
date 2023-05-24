return {
	-- Modify which-key keys
	{
		"folke/which-key.nvim",
		opts = function()
			require("which-key").register({
				["<leader>t"] = {
					name = "+test",
				},
				["<leader>gd"] = {
					name = "+diffview",
				},
			})
		end,
	},
}
