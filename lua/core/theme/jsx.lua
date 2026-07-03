local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "@tag.javascript", { link = "Type" })
  vim.api.nvim_set_hl(0, "@tag.builtin.javascript", { link = "@tag" })
  vim.api.nvim_set_hl(0, "@tag.attribute.javascript", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.javascriptreact", { fg = colors.yellow })
end

return M
