-- Reveal in finder
vim.keymap.set({"n", "v"}, "<leader>fi", function() vim.cmd[[silent !open -R %:p]] end)
