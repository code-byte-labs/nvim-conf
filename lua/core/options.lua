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
vim.o.completeopt = "menu,menuone,noselect,popup"
