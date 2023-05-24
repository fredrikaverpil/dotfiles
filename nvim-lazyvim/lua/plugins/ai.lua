return {

	-- chatgpt
	{
		"jackMort/ChatGPT.nvim",
		config = function()
			require("chatgpt").setup({
				-- optional configuration
				keymaps = {
					-- submit = "<C-a>", -- temporary solution, because of https://github.com/jackMort/ChatGPT.nvim/issues/99
				},
			})
		end,
		dependencies = {
			{ "MunifTanjim/nui.nvim" },
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-telescope/telescope.nvim" },
		},
	},
}
