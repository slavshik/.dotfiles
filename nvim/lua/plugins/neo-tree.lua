return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
        { "<leader>n", "<cmd>Neotree toggle<cr>", desc = "Neo-tree: toggle sidebar" },
        { "<leader>N", "<cmd>Neotree reveal<cr>", desc = "Neo-tree: reveal current file" },
        { "<leader>ng", "<cmd>Neotree float git_status<cr>", desc = "Neo-tree: git status" },
        { "<leader>nb", "<cmd>Neotree float buffers<cr>", desc = "Neo-tree: open buffers" },
    },
    opts = {
        -- oil owns netrw (default_file_explorer), so neo-tree stays out of it
        filesystem = {
            hijack_netrw_behavior = "disabled",
            filtered_items = {
                visible = true,
                hide_dotfiles = false,
                hide_gitignored = true,
            },
            -- Keep the tree in sync with the buffer you are editing
            follow_current_file = { enabled = true, leave_dirs_open = true },
            use_libuv_file_watcher = true,
        },
        window = {
            width = 34,
            mappings = {
                -- Space is the leader key, so don't let neo-tree swallow it
                ["<space>"] = "none",
                ["P"] = { "toggle_preview", config = { use_float = false, use_image_nvim = false } },
                ["h"] = "close_node",
                ["l"] = "open",
            },
        },
        -- Tabs across the top of the tree: Files / Buffers / Git
        source_selector = {
            winbar = true,
            sources = {
                { source = "filesystem", display_name = "  Files " },
                { source = "buffers", display_name = "  Bufs " },
                { source = "git_status", display_name = "  Git " },
            },
        },
        popup_border_style = "rounded",
        default_component_configs = {
            indent = { with_expanders = true },
            git_status = {
                symbols = {
                    added = "",
                    modified = "",
                    deleted = "✖",
                    renamed = "󰁕",
                    untracked = "",
                    ignored = "",
                    unstaged = "󰄱",
                    staged = "",
                    conflict = "",
                },
            },
        },
    },
}
