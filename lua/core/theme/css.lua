local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "cssBraces", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "cssCustomProp", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "cssFunctionName", { fg = colors.cyan })
  vim.api.nvim_set_hl(0, "cssUnitDecorators", { fg = colors.red })
  vim.api.nvim_set_hl(0, "cssPositioningAttr", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "@property.css", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "@variable.css", { fg = colors.red })
  vim.api.nvim_set_hl(0, "@type.css", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "@value.css", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "@unit.css", { fg = colors.red })
  vim.api.nvim_set_hl(0, "@function.css", { fg = colors.cyan })
  vim.api.nvim_set_hl(0, "@pseudo.css", { fg = colors.cyan })
  vim.api.nvim_set_hl(0, "@character.special.css", { fg = colors.red })
  vim.api.nvim_set_hl(0, "@id.css", { fg = colors.blue })
end

return M
