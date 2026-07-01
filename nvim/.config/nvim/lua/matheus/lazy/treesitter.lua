-- Treesitter — nvim-treesitter MAIN branch (required for Neovim 0.12+).
-- The old `master` branch is frozen and incompatible with 0.12's treesitter API.
-- On main: highlight is started manually (vim.treesitter.start) and parsers are
-- installed via require('nvim-treesitter').install{...}. Indentation is left to
-- Neovim's built-in filetype indent (treesitter's indentexpr is experimental).

local ensure_installed = {
    "lua", "vim", "vimdoc", "query",
    "javascript", "typescript", "tsx",
    "python",
    "rust",
    "go", "gomod", "gowork", "gosum",
    "json", -- the json parser also covers jsonc on the main branch
    "html", "css",
    "bash",
    "markdown", "markdown_inline",
    "yaml", "toml",
}

return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false, -- main branch does NOT support lazy-loading
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup()

            -- Install/update the parsers above (async; already-installed ones are skipped).
            require("nvim-treesitter").install(ensure_installed)

            -- Enable highlight + indent per buffer on FileType.
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("matheus_treesitter", { clear = true }),
                callback = function(args)
                    -- Highlight only. Indentation is intentionally left to Neovim's
                    -- built-in filetype indent + smartindent: treesitter's indentexpr
                    -- on the main branch is experimental and was mangling `=` reindents
                    -- (e.g. the gv=gv in the visual-mode J/K line-move mappings).
                    pcall(vim.treesitter.start, args.buf)
                end,
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = { lookahead = true },
                move = { set_jumps = true },
            })

            local select = require("nvim-treesitter-textobjects.select")
            local move = require("nvim-treesitter-textobjects.move")

            -- Select textobjects (visual + operator-pending): af/if, ac/ic, aa/ia
            local select_maps = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
                ["aa"] = "@parameter.outer",
                ["ia"] = "@parameter.inner",
            }
            for lhs, obj in pairs(select_maps) do
                vim.keymap.set({ "x", "o" }, lhs, function()
                    select.select_textobject(obj, "textobjects")
                end, { desc = "TS select " .. obj })
            end

            -- Movement between functions / classes: ]f [f, ]c [c
            local next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" }
            local prev_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" }
            for lhs, obj in pairs(next_start) do
                vim.keymap.set({ "n", "x", "o" }, lhs, function()
                    move.goto_next_start(obj, "textobjects")
                end, { desc = "TS next " .. obj })
            end
            for lhs, obj in pairs(prev_start) do
                vim.keymap.set({ "n", "x", "o" }, lhs, function()
                    move.goto_previous_start(obj, "textobjects")
                end, { desc = "TS prev " .. obj })
            end
        end,
    },
}
