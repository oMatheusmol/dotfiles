return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff_format", "ruff_organize_imports" },
                javascript = { "prettier" },
                javascriptreact = { "prettier" },
                typescript = { "prettier" },
                typescriptreact = { "prettier" },
                json = { "prettier" },
                html = { "prettier" },
                css = { "prettier" },
                markdown = { "prettier" },
                yaml = { "prettier" },
                go = { "goimports", "gofmt" },
                rust = { "rustfmt" },
            },
            format_on_save = {
                timeout_ms = 3000,
                lsp_fallback = true,
            },
        })

        vim.keymap.set({ "n", "v" }, "<leader>f", function()
            require("conform").format({ async = true, lsp_fallback = true })
        end, { desc = "Format buffer" })
    end,
}
