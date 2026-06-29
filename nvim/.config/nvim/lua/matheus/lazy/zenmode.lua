return {
    "folke/zen-mode.nvim",
    config = function()
        require("zen-mode").setup({
            window = {
                width = 90,
                options = {
                    signcolumn = "no",
                    number = false,
                    relativenumber = false,
                },
            },
        })
        vim.keymap.set("n", "<leader>zz", function()
            require("zen-mode").toggle()
            vim.wo.wrap = false
        end, { desc = "Toggle zen mode" })
    end,
}
