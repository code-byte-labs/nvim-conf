local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "tsxAttrib", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "tsxTagName", { link = "Type" })
  vim.api.nvim_set_hl(0, "tsxCloseString", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "@tag.tsx", { link = "Type" })
  vim.api.nvim_set_hl(0, "@tag.builtin.tsx", { link = "@tag" })
  vim.api.nvim_set_hl(0, "@type.tsx", { link = "@variable" })
  vim.api.nvim_set_hl(0, "@punctuation.bracket.tsx", { link = "@punctuation.bracket" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.typescriptreact", { fg = colors.yellow })
end

return M
