vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
  view = {
    width = 36,
  },
  renderer = {
    icons = {
      show = {
        git = false,
      },
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  callback = function()
    vim.opt_local.statusline = " "
  end,
})
