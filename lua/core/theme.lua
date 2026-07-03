-- 颜色主题与高亮覆盖

local onedark = require("onedarkpro.helpers")
local colors = onedark.get_colors("onedark")

local function nvim_set_hl_common()
  vim.api.nvim_set_hl(0, "@parameter", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "@constructor", { link = "keyword" })
  vim.api.nvim_set_hl(0, "@lsp.type.member", { link = "@function" })
  vim.api.nvim_set_hl(0, "@lsp.type.namespace", { link = "Type" })
  vim.api.nvim_set_hl(0, "@function.builtin", { link = "@function" })
  vim.api.nvim_set_hl(0, "@punctuation.bracket", { fg = colors.fg })
end

local function nvim_set_hl_typescript()
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

local function nvim_set_hl_tsx()
  vim.api.nvim_set_hl(0, "tsxAttrib", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "tsxTagName", { link = "Type" })
  vim.api.nvim_set_hl(0, "tsxCloseString", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "@tag.tsx", { link = "Type" })
  vim.api.nvim_set_hl(0, "@tag.builtin.tsx", { link = "@tag" })
  vim.api.nvim_set_hl(0, "@type.tsx", { link = "@variable" })
  vim.api.nvim_set_hl(0, "@punctuation.bracket.tsx", { link = "@punctuation.bracket" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.typescriptreact", { fg = colors.yellow })
end

local function nvim_set_hl_css()
  vim.api.nvim_set_hl(0, "cssBraces", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "cssCustomProp", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "cssFunctionName", { fg = colors.cyan })
  vim.api.nvim_set_hl(0, "cssUnitDecorators", { fg = colors.red })
  vim.api.nvim_set_hl(0, "cssPositioningAttr", { fg = colors.fg })
end

local function nvim_set_hl_less()
  vim.api.nvim_set_hl(0, "lessClass", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "lessFunction", { fg = colors.cyan })
end

local function nvim_set_hl_html()
  vim.api.nvim_set_hl(0, "htmlArg", { fg = colors.orange })
end

local function nvim_set_hl_markup()
  vim.api.nvim_set_hl(0, "@markup.heading", { fg = colors.fg })
end

local function nvim_set_hl_javascript()
  vim.api.nvim_set_hl(0, "@type.javascript", { link = "@variable" })
  vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.javascript", { fg = colors.yellow })
end

local function nvim_set_hl_jsx()
  vim.api.nvim_set_hl(0, "@tag.javascript", { link = "Type" })
  vim.api.nvim_set_hl(0, "@tag.builtin.javascript", { link = "@tag" })
  vim.api.nvim_set_hl(0, "@tag.attribute.javascript", { fg = colors.orange })
  vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.javascriptreact", { fg = colors.yellow })
end

local function nvim_set_hl_lua()
  vim.api.nvim_set_hl(0, "@keyword.operator.lua", { link = "keyword" })
end

local function nvim_set_hl_python()
  vim.api.nvim_set_hl(0, "@odp.import_module.python", { link = "Type" })
end

local function nvim_set_hl_nvim_tree()
  vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", {})
  vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = colors.fg })
  vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { fg = colors.fg })
end

-- onedark 主题专属高亮覆盖 (必须在 colorscheme 之前注册)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "onedark",
  callback = function()
    nvim_set_hl_lua()
    nvim_set_hl_tsx()
    nvim_set_hl_jsx()
    nvim_set_hl_css()
    nvim_set_hl_less()
    nvim_set_hl_html()
    nvim_set_hl_markup()
    nvim_set_hl_python()
    nvim_set_hl_common()
    nvim_set_hl_nvim_tree()
    nvim_set_hl_typescript()
    nvim_set_hl_javascript()
  end,
})

vim.cmd("colorscheme onedark")
