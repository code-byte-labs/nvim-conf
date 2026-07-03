local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "cssBraces", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "cssCustomProp", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "cssFunctionName", { fg = colors.cyan })
  vim.api.nvim_set_hl(0, "cssUnitDecorators", { fg = colors.red })
  vim.api.nvim_set_hl(0, "cssPositioningAttr", { fg = colors.fg })
end

return M
