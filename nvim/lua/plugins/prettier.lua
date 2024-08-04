return {
    "MunifTanjim/prettier.nvim",
    dependencies = {
        { "neovim/nvim-lspconfig" },
        { "jose-elias-alvarez/null-ls.nvim" },
    },
    opts = {
        bin = "prettierd",
    },
    cond = function()
        local prettier = require("prettier")
        return prettier.config_exists({ check_package_json = true })
    end
}
