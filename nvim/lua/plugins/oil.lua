return {
    init = function() 
        vim.keymap.set("n", "-", function()
            -- Get all windows in the current tab page
            local wins = vim.api.nvim_tabpage_list_wins(0)

            -- If only 1 window is open, create the split first
            if #wins == 1 then
                vim.cmd("vsplit | wincmd H")
            end 
            require("oil").open()
        end, 
        { desc = "Open Oil in vertical split" })
    end,
    "stevearc/oil.nvim", opts = {default_file_explorer = true},
}
