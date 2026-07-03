local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "typescriptBraces", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "typescriptOperator", { link = "keyword" })
  vim.api.nvim_set_hl(0, "typescriptEndColons", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "typescriptDecorator", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "typescriptArrowFunc", { link = "keyword" })
  vim.api.nvim_set_hl(0, "typescriptImportBlock", { fg = colors.red })
  vim.api.nvim_set_hl(0, "typescriptObjectLabel", { link = "@property" })
  vim.api.nvim_set_hl(0, "typescriptFuncCallArg", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "typescriptCastKeyword", { link = "keyword" })
  vim.api.nvim_set_hl(0, "typescriptFuncTypeArrow", { link = "keyword" })
  vim.api.nvim_set_hl(0, "typescriptIdentifierName", { fg = colors.red })
  vim.api.nvim_set_hl(0, "typescriptDefaultImportName", { fg = colors.red })
  vim.api.nvim_set_hl(0, "@punctuation.bracket.typescript", { link = "@punctuation.bracket" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.typescript", { fg = colors.yellow })
end

return M
