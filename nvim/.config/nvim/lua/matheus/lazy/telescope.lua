return {
    "nvim-telescope/telescope.nvim",
    tag = "v0.2.2", -- 0.1.8 usava a API antiga do nvim-treesitter (ft_to_lang), quebrada na branch main
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function()
                return vim.fn.executable("make") == 1
            end,
        },
    },
    config = function()
        local telescope = require("telescope")
        local builtin = require("telescope.builtin")

        -- Usa fdfind (nome do binário no Ubuntu/Debian)
        local fd_bin = vim.fn.executable("fd") == 1 and "fd" or "fdfind"

        -- Ignora esses diretórios SÓ nos pickers de arquivo/grep — nunca no defaults,
        -- senão os pickers de LSP (gd/gr/gI) filtram a definição de código de lib
        -- (node_modules, target/, site-packages...) e parece que "não achou".
        local ignore = { "node_modules", ".git/", "target/", "__pycache__" }

        telescope.setup({
            defaults = {
                mappings = {
                    i = { ["<C-u>"] = false, ["<C-d>"] = false },
                },
            },
            pickers = {
                find_files = {
                    find_command = { fd_bin, "--type", "f", "--hidden", "--exclude", ".git" },
                    file_ignore_patterns = ignore,
                },
                git_files = {
                    show_untracked = true,
                },
                live_grep = {
                    file_ignore_patterns = ignore,
                },
                grep_string = {
                    file_ignore_patterns = ignore,
                },
            },
        })

        pcall(telescope.load_extension, "fzf")

        vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Find files" })
        vim.keymap.set("n", "<C-p>", function()
            local git_ok = pcall(builtin.git_files)
            if not git_ok then
                builtin.find_files()
            end
        end, { desc = "Git files / find files" })
        vim.keymap.set("n", "<leader>ps", function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end, { desc = "Grep string" })
        vim.keymap.set("n", "<leader>pws", function()
            builtin.grep_string({ search = vim.fn.expand("<cword>") })
        end, { desc = "Grep word under cursor" })
        vim.keymap.set("n", "<leader>pWs", function()
            builtin.grep_string({ search = vim.fn.expand("<cWORD>") })
        end, { desc = "Grep WORD under cursor" })
        vim.keymap.set("n", "<leader>pb", builtin.buffers, { desc = "Buffers" })
        vim.keymap.set("n", "<leader>vh", builtin.help_tags, { desc = "Help tags" })
    end,
}
