return {
    "folke/persistence.nvim",
    -- Must load unconditionally, not lazily on an event: `nvim .` opens a
    -- netrw directory buffer, which never fires BufReadPre, so a
    -- BufReadPre-gated load would never register the restore autocmd below.
    lazy = false,
    opts = {},
    config = function(_, opts)
        require("persistence").setup(opts)

        -- Auto-restore only when nvim was opened with no file args, or just
        -- "." (a directory, like `nvim .`) — if you passed a specific file,
        -- assume you want to edit that fresh, not reopen the whole session.
        vim.api.nvim_create_autocmd("VimEnter", {
            group = vim.api.nvim_create_augroup("matheus_persistence_restore", { clear = true }),
            nested = true,
            callback = function()
                local args = vim.fn.argv()
                local no_real_file_args = #args == 0 or (#args == 1 and args[1] == ".")
                if no_real_file_args then
                    -- Defer: netrw sets up its directory buffer after VimEnter
                    -- when opened with `nvim .`, and would otherwise clobber
                    -- the just-restored session.
                    vim.schedule(function()
                        require("persistence").load()
                    end)
                end
            end,
        })
    end,
    keys = {
        {
            "<leader>qs",
            function()
                require("persistence").load()
            end,
            desc = "Restore session for this dir",
        },
        {
            "<leader>ql",
            function()
                require("persistence").load({ last = true })
            end,
            desc = "Restore last session (any dir)",
        },
        {
            "<leader>qd",
            function()
                require("persistence").stop()
            end,
            desc = "Don't save current session on exit",
        },
    },
}
