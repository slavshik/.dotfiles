return {
    "folke/sidekick.nvim",
    opts = {
        nes = { enabled = false }, -- needs Copilot LSP; CLI integration only
        cli = {
            mux = { backend = "tmux", enabled = true },
        },
    },
    keys = {
        {
            "<leader>ac",
            function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
            desc = "Sidekick: toggle Claude",
        },
        {
            "<leader>av",
            function() require("sidekick.cli").send({ msg = "{selection}" }) end,
            mode = { "x" },
            desc = "Sidekick: send selection",
        },
        {
            "<leader>ap",
            function() require("sidekick.cli").prompt() end,
            mode = { "n", "x" },
            desc = "Sidekick: select prompt",
        },
    },
}
