-- 基础设置 (vim.opt / vim.o)

-- statusline: 将文件名占位符 %f 换成绝对路径 %F
local statusline = vim.o.statusline
statusline = statusline:gsub("%%f", "%%F", 1)
vim.o.statusline = statusline

-- Tabline: show only the file name (tail) per tab, not the full path.
function _G.tabline()
  local s = ""
  for i = 1, vim.fn.tabpagenr("$") do
    -- Active tab uses TabLineSel, others use TabLine.
    s = s .. (i == vim.fn.tabpagenr() and "%#TabLineSel#" or "%#TabLine#")
    s = s .. "%" .. i .. "T " -- clickable: switches to tab i

    local buflist = vim.fn.tabpagebuflist(i)
    local winnr = vim.fn.tabpagewinnr(i)
    local bufnr = buflist[winnr]
    local name = vim.fn.bufname(bufnr)
    name = (name == "") and "[No Name]" or vim.fn.fnamemodify(name, ":t")

    -- Modified indicator.
    local modified = vim.fn.getbufvar(bufnr, "&modified") == 1 and " [+]" or ""
    s = s .. name .. modified .. " "
  end
  s = s .. "%#TabLineFill#%T"
  return s
end

vim.o.tabline = "%!v:lua.tabline()"
vim.o.showtabline = 1 -- 1: only when 2+ tabs; set 2 to always show

-- 内建补全
vim.o.autocomplete = true
-- 'autocomplete' 每次按键都会触发，但要拉取 LSP 结果必须包含 o(omnifunc)，
-- 因为 LSP attach 后 omnifunc = vim.lsp.omnifunc。去掉 o 会导致只有 LSP
-- 触发字符(如 Python 的 ")才出提示，输入字母/空格/删除时不出。
vim.o.complete = ".,o,w"
vim.o.completeopt = "menu,menuone,noselect,popup"

-- 代码折叠：默认用现有 Treesitter fold query；LSP 支持时在 LspAttach 中接管。
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldtext = "v:lua.vim.lsp.foldtext()"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
