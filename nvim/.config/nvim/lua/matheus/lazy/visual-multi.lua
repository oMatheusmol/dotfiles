return {
  "mg979/vim-visual-multi",
  event = "VeryLazy",
  config = function()
    vim.g.VM_maps = {
      ["Find Under"] = "<C-n>",
      ["Find Subword Under"] = "<C-n>",
      ["Select All"] = "<leader>A",
      ["Start Regex Search"] = "<leader>f",
      ["Add Cursor Down"] = "<C-j>",
      ["Add Cursor Up"] = "<C-k>",
    }
  end,
}
