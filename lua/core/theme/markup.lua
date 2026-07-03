local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "@markup.heading", { fg = colors.fg })
end

return M
