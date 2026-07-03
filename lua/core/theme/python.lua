local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "@odp.import_module.python", { link = "Type" })
end

return M
