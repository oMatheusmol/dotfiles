return {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        require("toggleterm").setup({
            direction = "float",
            float_opts = { border = "curved" },
        })

        local Terminal = require("toggleterm.terminal").Terminal

        -- --continue resumes the most recent conversation for this cwd;
        -- falls back to a fresh conversation when there isn't one yet.
        -- --dangerously-skip-permissions bypasses every permission prompt
        -- (edits, bash, etc). Deliberate tradeoff for this keymap only.
        local claude_term = Terminal:new({
            cmd = "claude --continue --dangerously-skip-permissions",
            direction = "float",
            hidden = true,
            on_open = function()
                vim.cmd("startinsert!")
            end,
        })

        -- Single chord, not a leader sequence: this fires in terminal mode
        -- (while typing into the claude process), so it must never be a
        -- prefix of normal typed text. <leader>ai (space+a+i) caused input
        -- lag on every space and would trigger mid-word (e.g. "ainda").
        vim.keymap.set({ "n", "t" }, "<C-t>", function()
            claude_term:toggle()
        end, { desc = "Toggle Claude Code terminal" })
    end,
}
