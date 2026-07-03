local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "@parameter", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "@constructor", { link = "keyword" })
  vim.api.nvim_set_hl(0, "@lsp.type.member", { link = "@function" })
  vim.api.nvim_set_hl(0, "@lsp.type.namespace", { link = "Type" })
  vim.api.nvim_set_hl(0, "@function.builtin", { link = "@function" })
  vim.api.nvim_set_hl(0, "@punctuation.bracket", { fg = colors.fg })
end

return M
