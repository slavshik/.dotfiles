-- https://github.com/lmburns/lf.nvim
require("lf").setup({
	default_cmd = "lf", -- default `lf` command
	default_action = "edit", -- default action when `Lf` opens a file
	default_actions = { -- default action keybindings
		["<Enter>"] = "edit",
		["<C-t>"] = "tabedit",
		["<C-x>"] = "split",
		["<C-v>"] = "vsplit",
		["<C-o>"] = "tab drop",
	},
	winblend = 0, -- psuedotransparency level
	dir = "gwd", -- directory where `lf` starts ('gwd' is git-working-directory, "" is CWD)
	direction = "float", -- window type: float horizontal vertical
	border = "single", -- border kind: single double shadow curved
	escape_quit = true, -- map escape to the quit command (so it doesn't go into a meta normal mode)
	focus_on_open = true, -- focus the current file when opening Lf (experimental)
	mappings = true, -- whether terminal buffer mapping is enabled
	tmux = false, -- tmux statusline can be disabled on opening of Lf
	highlights = { -- highlights passed to toggleterm
		Normal = { guibg = 0 },
		NormalFloat = { link = "Normal" },
		FloatBorder = {
			guifg = 0,
			guibg = 0,
		},
	},
	-- Layout configurations
	-- layout_mapping = "<A-u>", -- resize window with this key

	views = { -- window dimensions to rotate through
		{ width = 0.600, height = 0.600 },
		{
			width = 1.0 * vim.fn.float2nr(vim.fn.round(0.7 * vim.o.columns)) / vim.o.columns,
			height = 1.0 * vim.fn.float2nr(vim.fn.round(0.7 * vim.o.lines)) / vim.o.lines,
		},
		{ width = 0.800, height = 0.800 },
		{ width = 0.950, height = 0.950 },
	},
})

vim.keymap.set("n", "<Leader>lf", ":Lf<CR>")
