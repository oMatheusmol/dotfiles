return {
    "blazkowolf/gruber-darker.nvim",
    priority = 1000,
    config = function()
        require("gruber-darker").setup({
            bold = true,
            italic = {
                strings = false,
                comments = true,
                operators = false,
                folds = true,
            },
            undercurl = true,
            underline = true,
        })
        vim.cmd.colorscheme("gruber-darker")
    end,
}
