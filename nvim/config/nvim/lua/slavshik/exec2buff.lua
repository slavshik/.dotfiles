local function exec2buff(cmd, bufnr)
	bufnr = bufnr or vim.api.nvim_create_buf(false, true)
	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			print(data)
			vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
		end,
		on_stderr = function(_, data, _)
			vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
		end,
	})
end
return exec2buff
