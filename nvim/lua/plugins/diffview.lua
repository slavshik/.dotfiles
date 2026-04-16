return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open" },
		{ "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: repo history" },
		{ "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: current file history" },
	},
	opts = {
		enhanced_diff_hl = true,
		view = {
			merge_tool = {
				layout = "diff3_mixed",
				disable_diagnostics = true,
			},
		},
	},
}
