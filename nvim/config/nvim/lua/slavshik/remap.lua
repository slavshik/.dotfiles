local nnoremap = require("slavshik.keymap").nnoremap
-- local inoremap = require("slavshik.keymap").inoremap
local vnoremap = require("slavshik.keymap").vnoremap
local harpoon_ui = require("harpoon.ui")
local harpoon_mark = require("harpoon.mark")

-- Save/Quit
nnoremap("<Leader>q", "<cmd>q<CR>")
nnoremap("<Leader>Q", "<cmd>q!<CR>")
nnoremap("<Leader>wq", "<cmd>wq<CR>")
nnoremap("<Leader>w", "<cmd>w<CR>")

-- Telescope
local telescope = require("telescope")
telescope.setup({
	extensions = {
		file_browser = {
			theme = "ivy",
			-- disables netrw and use telescope-file-browser in its place
			-- hijack_netrw = true,
			mappings = {
				["i"] = {
					-- your custom insert mode mappings
				},
				["n"] = {
					-- your custom normal mode mappings
				},
			},
		},
	},
})
telescope.load_extension("harpoon")
telescope.load_extension("file_browser")
local ts = require("telescope.builtin")
-- nnoremap("<Leader>W", function()
-- 	require("telescope").extensions.file_browser.file_browser({ path = vim.fn.expand("%:p:h"), grouped = true })
-- end)
nnoremap("<Leader>W", "<cmd>Ex<CR>")
nnoremap("<Leader>t", "<cmd>Telescope<CR>")
nnoremap("<Leader>ff", function()
	ts.find_files({})
end)
nnoremap("<Leader>ee", function()
	ts.oldfiles({})
end)

nnoremap("<S><S>", "<cmd>Telescope<CR>")
nnoremap("<Leader>ds", function()
	ts.lsp_document_symbols()
end)
nnoremap("<Leader>F", function()
	ts.live_grep()
end)
-- nnoremap("<C-7>", "<cmd>Telescope string_grep<CR>")

-- Harpoon
local function harpoon_nav_file(n)
	return function()
		harpoon_ui.nav_file(n)
	end
end
nnoremap("<C-\\>", function()
	harpoon_mark.add_file()
end)
for i = 0, 9 do
	nnoremap("<Leader>" .. i, harpoon_nav_file(i))
end
nnoremap("<C-e>", "<cmd>Telescope harpoon marks<cr>")
nnoremap("<S-e>", function()
	harpoon_ui.toggle_quick_menu()
end)

-- MoveLine
nnoremap("∆", ":MoveLine(1)<CR>")
nnoremap("˚", ":MoveLine(-1)<CR>")
vnoremap("¬", ":MoveHBlock(1)<CR>")
vnoremap("˙", ":MoveHBlock(-1)<CR>")
vnoremap("∆", ":MoveBlock(1)<CR>")
vnoremap("˚", ":MoveBlock(-1)<CR>")
nnoremap("¬", ":MoveHChar(1)<CR>")
nnoremap("˙", ":movehchar(-1)<cr>")

nnoremap("Ô", "yyp") -- duplicate line and move down (alt+shift+j)
-- nnoremap("˚", "yyP") -- duplicate line and move up (alt+shift+k)

-- GIT!
nnoremap("<Leader>G", "<cmd>LazyGit<CR>")
