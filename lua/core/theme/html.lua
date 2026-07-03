local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "htmlArg", { fg = colors.orange })
end

return M
