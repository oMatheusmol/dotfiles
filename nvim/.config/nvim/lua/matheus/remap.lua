vim.g.mapleader = " "

-- File explorer
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "File explorer (netrw)" })

-- Move selected lines up/down.
-- Reindent (=) only when the buffer has a real indent method; otherwise `=`
-- would flatten the moved lines to column 0 in filetypes without an indent script.
local function move_selection(motion)
	-- Only indentexpr/cindent/lisp reindent reliably. smartindent is intentionally
	-- excluded: on its own (no indentexpr) it flattens reindented lines to column 0.
	local has_indent = vim.bo.indentexpr ~= ""
		or vim.bo.cindent
		or vim.bo.lisp
	local seq = ":m " .. motion .. "<CR>gv" .. (has_indent and "=gv" or "")
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(seq, true, false, true), "x", false)
end
vim.keymap.set("v", "J", function() move_selection("'>+1") end, { desc = "Move selection down" })
vim.keymap.set("v", "K", function() move_selection("'<-2") end, { desc = "Move selection up" })

-- Keep cursor centered
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join line (keep cursor)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- Paste without losing register
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste over (keep register)" })

-- Copy to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })

-- Delete to void register
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to void register" })

-- Escape from insert with Ctrl-c
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Escape" })

-- Disable Q
vim.keymap.set("n", "Q", "<nop>", { desc = "Disabled (was Ex mode)" })

-- Tmux sessionizer
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Tmux sessionizer" })

-- Quickfix navigation
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix item" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next loclist item" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Prev loclist item" })

-- Substitute word under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word under cursor" })

-- Make file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file executable" })

-- Reload config
vim.keymap.set("n", "<leader><leader>", function()
	vim.cmd("so")
end, { desc = "Source current file" })
