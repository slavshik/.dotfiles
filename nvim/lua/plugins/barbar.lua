return {
    {
        "romgrk/barbar.nvim",
        init = function()
            vim.g.barbar_auto_setup = false
            local map = vim.api.nvim_set_keymap
            local opts = { noremap = true, silent = true }

            -- TODO: remap to CMD
            map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", opts)
            map("n", "<A-.>", "<Cmd>BufferNext<CR>", opts)
            -- Close buffer
            map("n", "<A-w>", "<Cmd>BufferClose<CR>", opts)
        end,
        opts = {
            -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
            -- animation = true,
            -- insert_at_start = true,
            -- …etc.
        },
        version = "^1.0.0", -- optional: only update when a new 1.x version is released
    },
}
