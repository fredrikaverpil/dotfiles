return {
	-- Modify which-key keys
	{
		"folke/which-key.nvim",
		opts = function()
			require("which-key").register({
				["<leader>ct"] = {
					name = "+Test",
				},
			})
		end,
	},
}
