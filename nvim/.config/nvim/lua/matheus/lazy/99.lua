return {
    "ThePrimeagen/99",
    config = function()
        -- Strip the "99" branding from its floating window titles without
        -- forking: 99.window sets the title via nvim_open_win's native
        -- `title` field, so wrapping that call once here rewrites every
        -- title the plugin ever opens (" 99 Error " -> " Error ", etc).
        local orig_open_win = vim.api.nvim_open_win
        vim.api.nvim_open_win = function(buffer, enter, win_config)
            if win_config and type(win_config.title) == "string" then
                win_config.title = win_config.title:gsub("^(%s*)99%s*", "%1")
            end
            return orig_open_win(buffer, enter, win_config)
        end

        -- Auto-enter insert mode for the Search prompt window only (not
        -- Visual/Tutorial). capture_input's `name` arg distinguishes them.
        local Window = require("99.window")
        local orig_capture_input = Window.capture_input
        Window.capture_input = function(name, opts)
            local win = orig_capture_input(name, opts)
            if name == "Search" then
                vim.schedule(function()
                    vim.cmd("startinsert")
                end)
            end
            return win
        end

        local _99 = require("99")
        local cwd = vim.uv.cwd()
        local basename = vim.fs.basename(cwd)

        _99.setup({
            provider = _99.Providers.ClaudeCodeProvider,
            logger = {
                level = _99.DEBUG,
                path = "/tmp/" .. basename .. ".99.debug",
                print_on_error = true,
            },
            tmp_dir = "./tmp",
        })

        vim.keymap.set("v", "<leader>9v", function()
            _99.visual()
        end, { desc = "AI: replace visual selection" })

        vim.keymap.set("n", "<leader>9s", function()
            _99.search()
        end, { desc = "AI: search project" })

        vim.keymap.set("n", "<leader>9x", function()
            _99.stop_all_requests()
        end, { desc = "AI: cancel in-flight requests" })

        vim.keymap.set("n", "<leader>9o", function()
            _99.open()
        end, { desc = "AI: open last result" })

        vim.keymap.set("n", "<leader>9l", function()
            _99.view_logs()
        end, { desc = "AI: view logs" })

        -- Requires telescope.nvim (already installed in this config)
        vim.keymap.set("n", "<leader>9m", function()
            require("99.extensions.telescope").select_model()
        end, { desc = "AI: select model" })

        vim.keymap.set("n", "<leader>9p", function()
            require("99.extensions.telescope").select_provider()
        end, { desc = "AI: select provider" })

        -- 99 scans the project's @-file list once per session and never
        -- rescans (get_files() only recomputes when its cache is empty).
        -- New files created after that first scan won't show up in @
        -- completion until this clears the cache to force a rescan.
        vim.keymap.set("n", "<leader>9r", function()
            local Files = require("99.extensions.files")
            Files.set_project_root(Files.get_project_root())
            vim.notify("AI: file list refreshed", vim.log.levels.INFO)
        end, { desc = "AI: refresh @file list" })
    end,
}
