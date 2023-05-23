return {

	-- change telescope config
	{
		"nvim-telescope/telescope.nvim",

		dependencies = {
			"nvim-telescope/telescope-live-grep-args.nvim",
		},
		config = function()
			-- https://github.com/nvim-telescope/telescope-live-grep-args.nvim
			require("telescope").load_extension("live_grep_args")
		end,
		keys = {
			{
				"<leader>/",
				function()
					require("telescope.").extensions.live_grep_args.live_grep_args()
				end,
				desc = "Find Plugin File",
			},
		},

		-- opts will be merged with the parent spec
		opts = {
			defaults = {
				file_ignore_patterns = { "^.git/", "^node_modules/", "^poetry.lock" },
			},
			pickers = {
				live_grep = {
					additional_args = function()
						return { "--hidden" }
					end,
				},
			},
		},
	},
}
