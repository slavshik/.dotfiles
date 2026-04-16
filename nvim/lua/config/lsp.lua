require('mini.snippets').setup({})
require('mini.completion').setup({})

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN]  = "",
            [vim.diagnostic.severity.HINT]  = "󰌵",
            [vim.diagnostic.severity.INFO]  = "",
        },
    },
})

vim.lsp.enable({
    "ts_ls",
    "eslint",
    "luals",
    "gopls",
})

-- ESLint fix on save (matches WebStorm: **/*.{js,ts,jsx,tsx,html,vue})
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.js", "*.ts", "*.jsx", "*.tsx", "*.html", "*.vue" },
    callback = function(args)
        local clients = vim.lsp.get_clients({ bufnr = args.buf, name = "eslint" })
        if #clients > 0 then
            vim.cmd("silent! LspEslintFixAll")
        end
    end,
})

local function organize_imports()
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "ts_ls" })
    if #clients > 0 then
        vim.lsp.buf_request_sync(0, "workspace/executeCommand", {
            command = "_typescript.organizeImports",
            arguments = { vim.api.nvim_buf_get_name(0) },
        }, 3000)
    else
        vim.lsp.buf.code_action({
            context = { only = { "source.organizeImports" }, diagnostics = {} },
            apply = true,
        })
    end
end

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local opts = { buffer = args.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>OI", organize_imports, opts)
    end,
})
