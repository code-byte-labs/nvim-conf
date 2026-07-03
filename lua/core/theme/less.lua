local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "lessClass", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "lessFunction", { fg = colors.cyan })
end

return M
