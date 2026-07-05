return {
  "f-person/git-blame.nvim",
  event = "VeryLazy",
  config = function()
    vim.api.nvim_set_hl(0, "GitBlameStatusLine", {
      fg = "#333333",
      italic = true,
    })

    require("gitblame").setup({
      enabled = true,
      message_template = " <author> • <date>",
      date_format = "%r",
      virtual_text_column = 120,
      highlight_group = "GitBlameStatusLine",
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "GitBlameStatusLine", {
          fg = "#333333",
          italic = true,
            })
      end,
    })
  end,
}
