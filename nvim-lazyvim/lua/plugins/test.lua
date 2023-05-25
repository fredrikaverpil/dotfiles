return {

	{
		"nvim-neotest/neotest",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
			{ "nvim-treesitter/nvim-treesitter" },
			{ "antoinemadec/FixCursorHold.nvim" },

			-- adapters
			{
				"nvim-neotest/neotest-python",
			},
		},
		keys = {
			{ "<leader>tt", ":lua require('neotest').run.run()<CR>", desc = "Run nearest test" },
			{ "<leader>tl", ":lua require('neotest').run.run_last()<CR>", desc = "Run last test" },
			{ "<leader>tf", ":lua require('neotest').run.run(vim.fn.expand('%'))<CR>", desc = "Run tests in file" },
			{ "<leader>ts", ":lua require('neotest').summary.toggle()<CR>", desc = "Run test summary" },
			{ "<leader>to", ":lua require('neotest').output.open({ enter = true })<CR>", desc = "Run test output" },
			{ "<leader>tp", ":lua require('neotest').output_panel.toggle()<CR>", desc = "Run test output panel" },

			-- debugging via nvim-dap, see debug.lua
			{ "<leader>td", ":lua require('neotest').run.run({ strategy = 'dap' })<CR>", desc = "Debug nearest test" },
		},
		config = function()
			-- Setup neotest adapter for python
			require("neotest").setup({
				adapters = {
					require("neotest-python")({
						runner = "pytest",
						args = { "--log-level", "DEBUG", "--color", "yes" },
					}),
				},
			})
		end,
	},
}
