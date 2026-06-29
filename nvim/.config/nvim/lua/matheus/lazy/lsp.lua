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
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "rust_analyzer",
                    "pyright",
                    "ts_ls",
                    "gopls",
                    "eslint",
                    "tailwindcss",
                },
                handlers = {
                    function(server_name)
                        require("lspconfig")[server_name].setup({ capabilities = capabilities })
                    end,

                    ["lua_ls"] = function()
                        require("lspconfig").lua_ls.setup({
                            capabilities = capabilities,
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
                    end,

                    ["gopls"] = function()
                        require("lspconfig").gopls.setup({
                            capabilities = capabilities,
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
                    end,

                    ["pyright"] = function()
                        require("lspconfig").pyright.setup({
                            capabilities = capabilities,
                            settings = {
                                python = {
                                    analysis = {
                                        typeCheckingMode = "basic",
                                    },
                                },
                            },
                        })
                    end,
                },
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
                float = { focusable = false, style = "minimal", border = "rounded" },
                virtual_text = { spacing = 4, prefix = "●" },
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,
            })

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
