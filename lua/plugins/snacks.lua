require("snacks").setup({
  input = {
    win = {
      row = false,
      col = false,
    },
  },
  picker = {},
})
Snacks.input.enable()
vim.ui.select = Snacks.picker.select
