return {
    "coder/claudecode.nvim",
    -- WebSocket server only (no UI): sidekick.nvim owns the terminal,
    -- Claude discovers the editor via the lock file in ~/.claude/ide/
    opts = {
        terminal = { provider = "none" },
    },
}
