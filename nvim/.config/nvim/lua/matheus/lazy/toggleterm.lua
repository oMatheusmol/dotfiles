return {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        require("toggleterm").setup({
            direction = "float",
            float_opts = { border = "curved" },
        })

        local Terminal = require("toggleterm.terminal").Terminal

        -- Claude Code errors in interactive mode when --continue is passed
        -- but no prior conversation exists for this cwd (unlike --print,
        -- which silently starts fresh). Its project dir name is just the
        -- cwd with every "/" turned into "-", e.g. /a/b -> -a-b — check for
        -- that before deciding whether --continue is safe to pass.
        local function claude_cmd()
            local cwd = vim.uv.cwd()
            local project_dir = vim.fn.expand("~/.claude/projects/" .. cwd:gsub("/", "-"))
            local has_session = #vim.fn.glob(project_dir .. "/*.jsonl", false, true) > 0
            local base = "claude --dangerously-skip-permissions"
            return has_session and (base .. " --continue") or base
        end

        -- --dangerously-skip-permissions bypasses every permission prompt
        -- (edits, bash, etc). Deliberate tradeoff for this keymap only.
        local claude_term = Terminal:new({
            cmd = claude_cmd,
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
