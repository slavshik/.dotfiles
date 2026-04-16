return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        { "catppuccin/nvim", name = "catppuccin" },
    },
    config = function()
        -- vim.api.nvim_set_hl(O, "Normal", {_bg = "none" })
        vim.o.background = "dark"
        vim.cmd([[
            colorscheme catppuccin-nvim
            hi normal guibg=None
            highlight iCursor guifg=None guibg=red
            highlight Cursor guifg=white guibg=black
            highlight iCursor guifg=white guibg=red
            set guicursor=n-v-c:block-Cursor
            set guicursor+=i:block-iCursor
            set guicursor+=n-v-c:blinkon0
            set guicursor+=i:blinkwait10
        ]])
        require("lualine").setup({
            options = {
                theme = "catppuccin-nvim",
                disabled_filetypes = { "packer", "NvimTree" },
            },
        })
    end,
}
