return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "j-hui/fidget.nvim",
        },
        config = function()
            local cmp = require("cmp")
            local cmp_lsp = require("cmp_nvim_lsp")
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities()
            )

            require("fidget").setup({})
            require("mason").setup()

            -- Compose files are detected as plain `yaml`, but the compose LSP only
            -- attaches to `yaml.docker-compose`, so tag them (yamlls still attaches too).
            vim.filetype.add({
                pattern = {
                    ["docker%-compose%.ya?ml"] = "yaml.docker-compose",
                    ["docker%-compose%..*%.ya?ml"] = "yaml.docker-compose",
                    ["compose%.ya?ml"] = "yaml.docker-compose",
                    ["compose%..*%.ya?ml"] = "yaml.docker-compose",
                },
            })

            -- Neovim 0.11+ / mason-lspconfig v2: the old `handlers` API is gone.
            -- Servers are configured with vim.lsp.config() and auto-enabled by
            -- mason-lspconfig (which calls vim.lsp.enable() for installed servers).

            -- Default config merged into every server.
            vim.lsp.config("*", { capabilities = capabilities })

            -- Per-server overrides (previously the mason-lspconfig `handlers`).
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
            })

            vim.lsp.config("gopls", {
                settings = {
                    gopls = {
                        hints = {
                            assignVariableTypes = true,
                            compositeLiteralFields = true,
                            functionTypeParameters = true,
                            parameterNames = true,
                            rangeVariableTypes = true,
                        },
                    },
                },
            })

            vim.lsp.config("pyright", {
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode = "basic",
                        },
                    },
                },
            })

            -- ts_ls resolves tsserver from the workspace's own node_modules
            -- or its own bundled copy — it does NOT check a global npm
            -- install. Point it at the global one explicitly as a fallback
            -- for workspaces/machines where neither of those is available.
            do
                local npm_root = vim.trim(vim.fn.system("npm root -g"))
                local ts_lib = npm_root .. "/typescript/lib"
                if vim.fn.isdirectory(ts_lib) == 1 then
                    vim.lsp.config("ts_ls", {
                        init_options = {
                            tsserver = { path = ts_lib },
                        },
                    })
                end
            end

            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "rust_analyzer",
                    "pyright",
                    "ts_ls",
                    "gopls",
                    "eslint",
                    "tailwindcss",
                    "jsonls",
                    "yamlls",
                    "bashls",
                    "dockerls",
                    "clangd",
                    "html",
                    "cssls",
                    "marksman",
                    "docker_compose_language_service",
                },
                -- Exclude basedpyright so Python uses pyright (configured above)
                -- instead of double-attaching a second type checker. ruff still attaches.
                automatic_enable = { exclude = { "basedpyright" } },
            })

            local luasnip = require("luasnip")
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
                    ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
                    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                }),
            })

            vim.diagnostic.config({
                float = { focusable = false, style = "minimal", border = "rounded", source = true },
                virtual_text = { spacing = 4, prefix = "●" },
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,
            })

            vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show full error" })
            vim.keymap.set("n", "[e", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
            vim.keymap.set("n", "]e", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("forge-lsp-attach", { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end
                    local builtin = require("telescope.builtin")

                    map("gd", builtin.lsp_definitions, "Go to definition")
                    map("gr", builtin.lsp_references, "Go to references")
                    map("gI", builtin.lsp_implementations, "Go to implementation")
                    map("<leader>D", builtin.lsp_type_definitions, "Type definition")
                    map("<leader>ds", builtin.lsp_document_symbols, "Document symbols")
                    map("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "Workspace symbols")
                    map("<leader>rn", vim.lsp.buf.rename, "Rename")
                    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
                    map("K", vim.lsp.buf.hover, "Hover docs")
                    map("<leader>zig", "<cmd>LspRestart<CR>", "Restart LSP")
                end,
            })
        end,
    },
}
