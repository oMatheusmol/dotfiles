return {
    "windwp/nvim-ts-autotag",
    -- Carrega só nos filetypes com tags. Usa o treesitter (main) já instalado.
    ft = {
        "html", "xml", "svg",
        "javascript", "javascriptreact", "jsx",
        "typescript", "typescriptreact", "tsx",
        "vue", "svelte", "php", "markdown",
    },
    config = function()
        require("nvim-ts-autotag").setup()
    end,
}
