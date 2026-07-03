local M = {}

function M.setup(colors)
  vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", {})
  vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { fg = colors.fg })
end

return M
