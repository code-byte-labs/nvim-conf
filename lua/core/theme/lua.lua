local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "@keyword.operator.lua", { link = "keyword" })
end

return M
