require("snacks").setup({
  input = {
    win = {
      row = false,
      col = false,
    },
  },
  picker = {},
  scroll = {},
})
Snacks.input.enable()
vim.ui.select = Snacks.picker.select
