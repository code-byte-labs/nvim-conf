local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "@type.javascript", { link = "@variable" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.javascript", { fg = colors.yellow })
end

return M
