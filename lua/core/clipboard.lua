-- 剪贴板：SSH 下用 OSC 52 只写（Windows Terminal/conpty 不支持 OSC 52 读取，
-- 查询会超时）。复制用 "+y / "*y，粘贴进 vim 用终端的 Ctrl+Shift+V。
local osc52 = require('vim.ui.clipboard.osc52')

local is_ssh = vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT or vim.env.SSH_TTY

if is_ssh then
  vim.g.clipboard = {
    name = 'osc52-copy-only',
    copy = {
      ['+'] = osc52.copy('+'),
      ['*'] = osc52.copy('*'),
    },
    paste = {
      ['+'] = function() return {} end,
      ['*'] = function() return {} end,
    },
  }
  vim.keymap.set('n', 'y', '"+y')
  vim.keymap.set('v', 'y', '"+y')
else
  vim.opt.clipboard = 'unnamedplus'
end
