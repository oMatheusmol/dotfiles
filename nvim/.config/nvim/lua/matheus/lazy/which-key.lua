return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
        local wk = require("which-key")
        wk.setup({})

        -- Nomeia os prefixos de <leader> pra aparecerem organizados no popup.
        -- Os atalhos individuais aparecem sozinhos (usam o `desc` de cada keymap).
        wk.add({
            { "<leader>p", group = "Pesquisa/Projeto" },
            { "<leader>g", group = "Git" },
            { "<leader>t", group = "Trouble" },
            { "<leader>h", group = "Harpoon/Hunks" },
        })
    end,
}
