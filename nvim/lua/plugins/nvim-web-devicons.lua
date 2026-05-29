return {
    "nvim-tree/nvim-web-devicons",
    opts = {
        -- Match CSS/PCSS icons used in lf and lazygit.
        override_by_extension = {
            css = {
                icon = "",
                color = "#663399",
                cterm_color = "91",
                name = "Css",
            },
            pcss = {
                icon = "",
                color = "#663399",
                cterm_color = "91",
                name = "Pcss",
            },
        },
    },
}
