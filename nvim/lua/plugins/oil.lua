return {
    init = function() vim.keymap.set({"n", "v"}, "-", vim.cmd.Oil, {desc = "Open oil"} ) end,
    "stevearc/oil.nvim", opts = {default_file_explorer = true},
}
