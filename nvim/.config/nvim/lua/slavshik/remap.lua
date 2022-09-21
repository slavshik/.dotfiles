local nnoremap = require("slavshik.keymap").nnoremap
local inoremap = require("slavshik.keymap").inoremap
local vnoremap = require("slavshik.keymap").vnoremap
local harpoon_ui = require("harpoon.ui")
local harpoon_mark = require("harpoon.mark")

-- Save/Quit
-- nnoremap("<Leader>W", "<cmd>Ex<CR>")
-- nnoremap("<Leader>W", "<cmd>Lf<CR>")
nnoremap("<Leader>q", "<cmd>q<CR>")
nnoremap("<Leader>Q", "<cmd>q!<CR>")
nnoremap("<Leader>wq", "<cmd>wq<CR>")
nnoremap("<Leader>w", "<cmd>w<CR>")

-- Telescope
nnoremap("<C-p>", "<cmd>Telescope find_files<CR>")
nnoremap("<C-P", "<cmd>Telescope<CR>")
nnoremap('¶', "<cmd>Telescope lsp_references<CR>")
nnoremap('<C-l>', "<cmd>Telescope lsp_document_symbols<CR>zz")
nnoremap("<Leader>t", "<cmd>Telescope<CR>")
nnoremap("<Leader>F", "<cmd>Telescope live_grep<CR>")
nnoremap("<C-7>", "<cmd>Telescope string_grep<CR>")

-- Harpoon
local function harpoon_nav_file(n)
    return function()
        harpoon_ui.nav_file(n)
    end
end
nnoremap("<C-\\>", function() harpoon_mark.add_file() end)
for i = 0, 9 do
    nnoremap('<Leader>' .. i, harpoon_nav_file(i))
end
require("telescope").load_extension('harpoon')
nnoremap("<C-e>", "<cmd>Telescope harpoon marks<cr>")
nnoremap("<S-e>", function() harpoon_ui.toggle_quick_menu() end)

-- MoveLine
nnoremap('∆', ":MoveLine(1)<CR>")
nnoremap('˚', ":MoveLine(-1)<CR>")
vnoremap('¬', ":MoveHBlock(1)<CR>")
vnoremap('˙', ":MoveHBlock(-1)<CR>")
vnoremap('∆', ":MoveBlock(1)<CR>") 
vnoremap('˚', ":MoveBlock(-1)<CR>")
nnoremap('¬', ":MoveHChar(1)<CR>") 
nnoremap('˙', ":MoveHChar(-1)<CR>")

-- GIT!
nnoremap("<Leader>G", "<cmd>LazyGit<CR>")
