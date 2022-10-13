local function get_port_and_token(path)
	local f = io.lines(path)
	for line in f do
		local t = {}
		for str in string.gmatch(line, "([^" .. " " .. "]+)") do
			table.insert(t, str)
		end
		return t[1], t[2]
	end
end

-- TODO: use with TCP
-- local port, token = get_port_and_token("/Users/kvinty/.prettierd")

local prettier = require("prettier")
prettier.setup({ bin = "prettierd" })
