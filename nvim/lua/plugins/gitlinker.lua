return {
	"linrongbin16/gitlinker.nvim",
	cmd = "GitLink",
	keys = {
		{ "R", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "Copy git permalink" },
		{ "<leader>G", "<cmd>GitLink!<cr>", mode = { "n", "v" }, desc = "Open git permalink in browser" },
	},
	opts = function()
		local routers = require("gitlinker.routers")
		return {
			router = {
				browse = {
					["^gitlab%.gosystem%.io"] = routers.gitlab_browse,
					["^gitlab%.evolution%.com"] = routers.gitlab_browse,
				},
				default_branch = {
					["^gitlab%.gosystem%.io"] = routers.gitlab_default_branch,
					["^gitlab%.evolution%.com"] = routers.gitlab_default_branch,
				},
				current_branch = {
					["^gitlab%.gosystem%.io"] = routers.gitlab_current_branch,
					["^gitlab%.evolution%.com"] = routers.gitlab_current_branch,
				},
			},
		}
	end,
}
