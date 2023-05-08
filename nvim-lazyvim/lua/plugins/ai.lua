return {

	-- github copilot
	{
		"github/copilot.vim",
		-- automatically start github copilot
		config = function()
			vim.keymap.set(
				"i",
				"<C-J>",
				'copilot#Accept("<CR>")',
				{ silent = true, expr = true, replace_keycodes = false }
			)
			vim.keymap.set("i", "<C-H>", "copilot#Previous()", { silent = true, expr = true, replace_keycodes = false })
			vim.keymap.set("i", "<C-K>", "copilot#Next()", { silent = true, expr = true })
		end,
	},

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
