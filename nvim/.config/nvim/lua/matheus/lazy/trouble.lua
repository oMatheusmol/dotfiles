return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("trouble").setup({
            icons = true,
        })
        vim.keymap.set("n", "<leader>tt", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Trouble diagnostics" })
        vim.keymap.set("n", "<leader>tq", "<cmd>Trouble qflist toggle<CR>", { desc = "Trouble quickfix" })
        vim.keymap.set("n", "<leader>tl", "<cmd>Trouble loclist toggle<CR>", { desc = "Trouble loclist" })
        vim.keymap.set("n", "gR", "<cmd>Trouble lsp_references toggle<CR>", { desc = "Trouble LSP references" })
    end,
}
