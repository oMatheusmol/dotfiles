return {
    "tpope/vim-fugitive",
    config = function()
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status" })
        vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<CR>", { desc = "Git diff" })
        vim.keymap.set("n", "<leader>gb", "<cmd>Git blame<CR>", { desc = "Git blame" })
        vim.keymap.set("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "Git push" })
        vim.keymap.set("n", "<leader>gl", "<cmd>Git pull<CR>", { desc = "Git pull" })

        local forge_fugitive = vim.api.nvim_create_augroup("forge_fugitive", {})
        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = forge_fugitive,
            pattern = "*",
            callback = function()
                if vim.bo.ft ~= "fugitive" then return end
                local buf = vim.api.nvim_get_current_buf()
                vim.keymap.set("n", "<leader>p", function()
                    vim.cmd.Git({ "push" })
                end, { buffer = buf, remap = false })
                vim.keymap.set("n", "<leader>P", function()
                    vim.cmd.Git({ "pull", "--rebase" })
                end, { buffer = buf, remap = false })
            end,
        })
    end,
}
