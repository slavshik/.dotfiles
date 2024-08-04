return { 'nvim-telescope/telescope.nvim', tag = '0.1.8', 
    dependencies = { 
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-file-browser.nvim',
        "natecraddock/telescope-zf-native.nvim",
        "nvim-telescope/telescope-live-grep-args.nvim"
    },
    config = function()
        local telescope = require("telescope")
        local fb_actions = telescope.extensions.file_browser.actions

        telescope.setup({
            defaults = {
                layout_config = {
                    horizontal = {
                        width = 0.9,
                        height = 0.9,
                        preview_width = 0.5,
                    },
                    vertical = {
                        width = 0.9,
                        height = 0.9,
                        preview_height = 0.5,
                    },
                },
            },
            pickers = {
                find_files = {
                    theme = "dropdown",
                    previewer = false,
                },
                lsp_document_symbols = {
                    theme = "dropdown",
                },
            },
            extensions = {
                file_browser = {
                    layout_strategy = "center",
                    layout_config = {
                        prompt_position = "bottom",
                        width = 0.9,
                        height = 0.9,
                    },
                    -- disables netrw and use telescope-file-browser in its place
                    -- hijack_netrw = true,
                    mappings = {
                        ["i"] = {
                            -- your custom insert mode mappings
                        },
                        ["n"] = {
                            ["-"] = fb_actions.goto_parent_dir,
                        },
                    },
                },
            },
        })

        require("telescope").load_extension("file_browser")
        require("telescope").load_extension("live_grep_args")
        require("telescope").load_extension("zf-native")

        vim.keymap.set("n", "<leader>O", function()
            require("telescope").extensions.file_browser.file_browser()
        end, { desc = "File browser" })

        local builtin = require("telescope.builtin")

        vim.keymap.set("n", "<leader>t", vim.cmd.Telescope, { desc = "Telescope" })
        vim.keymap.set("n", "<leader>o", builtin.find_files, { desc = "Find files <CMD + Shift + F>" })
        --------------------------------------------------------------
        vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, { desc = "Document symbols" })
        vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Git files" })
        -- vim.keymap.set("n", "<leader>FF", builtin.live_grep, { desc = "Live grep" })
        vim.keymap.set("n", "<leader>FF", function()
            require("telescope").extensions.live_grep_args.live_grep_args()
        end, { desc = "Live grep" })
        vim.keymap.set("v", "<leader>FF", builtin.grep_string, { desc = "Grep string" })
        vim.keymap.set("n", "<leader>e", builtin.buffers, { desc = "Buffers" })

    end
}
