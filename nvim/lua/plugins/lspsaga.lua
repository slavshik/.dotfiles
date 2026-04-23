return {
    "nvimdev/lspsaga.nvim",
    opts = {
        ui = {
            theme = "round",
            border = "rounded",
            winblend = 0,
        },
        symbol_in_winbar = {
            enable = true,
            color_mode = true,
            show_file = true,
            folder_level = 3,
            separator = " · ",
        },
        code_action = {
            extend_gitsigns = true,
        },
    },
    config = function(_, opts)
        require("lspsaga").setup(opts)
        -- Guard against deleted augroup IDs (lspsaga outline bug)
        local ok, outline = pcall(require, "lspsaga.symbol.outline")
        if ok and outline.clean_ctx then
            local orig = outline.clean_ctx
            outline.clean_ctx = function(...)
                pcall(orig, ...)
            end
        end
    end,
    init = function()
        vim.keymap.set("n", ">", function()
            vim.cmd([[Lspsaga code_action]])
        end)
        vim.keymap.set("n", "<Leader>lo", function()
            vim.cmd([[Lspsaga outline]])
        end, { desc = "LSP outline" })
        local rename = function()
            vim.cmd([[Lspsaga rename]])
            vim.cmd.wa()
        end
        vim.keymap.set({ "n", "v" }, "<S-F6>", rename, { desc = "LSP rename" })
        vim.keymap.set({ "n", "v" }, "<leader>r", rename, { desc = "LSP rename" })
        vim.keymap.set("n", "<C-n>", function()
            vim.cmd([[Lspsaga diagnostic_jump_next]])
        end, { desc = "LSP next diagnostic" })
        vim.keymap.set("n", "<C-p>", function()
            vim.cmd([[Lspsaga diagnostic_jump_prev]])
        end, { desc = "LSP previous diagnostic" })

        vim.keymap.set("n", "<leader>i", function()
            vim.cmd([[Lspsaga show_cursor_diagnostics]])
        end, { desc = "LSP show cursor diagnostics" })
    end,
}
