return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        -- Trouble v3: `icons` expects a table, not a boolean. Use the defaults
        -- (nvim-web-devicons is a dependency), so pass no `icons` override.
        require("trouble").setup({})
        vim.keymap.set("n", "<leader>tt", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Trouble diagnostics" })
        vim.keymap.set("n", "<leader>tq", "<cmd>Trouble qflist toggle<CR>", { desc = "Trouble quickfix" })
        vim.keymap.set("n", "<leader>tl", "<cmd>Trouble loclist toggle<CR>", { desc = "Trouble loclist" })
        vim.keymap.set("n", "gR", "<cmd>Trouble lsp_references toggle<CR>", { desc = "Trouble LSP references" })
    end,
}
