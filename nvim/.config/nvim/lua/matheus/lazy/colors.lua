return {
    "thimc/gruber-darker.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("gruber-darker").setup({
            transparent = true,
            bold = true,
            underline = true,
        })
        vim.cmd.colorscheme("gruber-darker")
    end,
}
