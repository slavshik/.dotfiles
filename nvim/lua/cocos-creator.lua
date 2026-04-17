local function is_cocos_project(file_path)
    local dir = vim.fn.fnamemodify(file_path, ":p:h")
    while dir ~= "/" do
        local f = io.open(dir .. "/project.json", "r")
        if f then
            local content = f:read("*a")
            f:close()
            if content:find('"engine"%s*:%s*"cocos%-creator%-js"') then
                return true
            end
        end
        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then break end
        dir = parent
    end
    return false
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.anim", "*.meta" },
    callback = function(ev)
        if is_cocos_project(ev.file) then
            vim.bo.filetype = "json"
        end
    end,
})
